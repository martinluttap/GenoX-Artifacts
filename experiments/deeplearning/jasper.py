# Source: https://github.com/NVIDIA/NeMo/blob/main/tutorials/asr/ASR_with_NeMo.ipynb

import os
import librosa
import IPython.display as ipd
import glob
import json
import os
import subprocess
import tarfile
import wget
from pathlib import Path

# NeMo's "core" package
import nemo
# NeMo's ASR collection - this collections contains complete ASR models and
# building blocks (modules) for ASR
import nemo.collections.asr as nemo_asr

## Custom logging for timestamp 
import logging
import time
from datetime import datetime as dt
from typing import Any

import lightning as L
import pytorch_lightning as pl
from pytorch_lightning import Callback, Trainer
from pytorch_lightning.utilities import rank_zero_only
from pytorch_lightning.utilities.types import STEP_OUTPUT

logger = logging.getLogger(__name__)



# This is where the an4/ directory will be placed.
# Change this if you don't want the data to be extracted in the current directory.
data_dir = '.'

if not os.path.exists(data_dir):
  os.makedirs(data_dir)

# Download the dataset. This will take a few moments...
print("******")
if not os.path.exists(data_dir + '/an4_sphere.tar.gz'):
    an4_url = 'https://dldata-public.s3.us-east-2.amazonaws.com/an4_sphere.tar.gz'
    an4_path = wget.download(an4_url, data_dir)
    print(f"Dataset downloaded at: {an4_path}")
else:
    print("Tarfile already exists.")
    an4_path = data_dir + '/an4_sphere.tar.gz'

if not os.path.exists(data_dir + '/an4/'):
    # Untar and convert .sph to .wav (using sox)
    tar = tarfile.open(an4_path)
    tar.extractall(path=data_dir)

    print("Converting .sph to .wav...")
    sph_list = glob.glob(data_dir + '/an4/**/*.sph', recursive=True)
    for sph_path in sph_list:
        wav_path = sph_path[:-4] + '.wav'
        cmd = ["sox", sph_path, wav_path]
        subprocess.run(cmd)
print("Finished conversion.\n******")

# Function to build a manifest
def build_manifest(transcripts_path, manifest_path, wav_path):
    with open(transcripts_path, 'r') as fin:
        with open(manifest_path, 'w') as fout:
            for line in fin:
                # Lines look like this:
                # <s> transcript </s> (fileID)
                transcript = line[: line.find('(')-1].lower()
                transcript = transcript.replace('<s>', '').replace('</s>', '')
                transcript = transcript.strip()

                file_id = line[line.find('(')+1 : -2]  # e.g. "cen4-fash-b"
                audio_path = os.path.join(
                    data_dir, wav_path,
                    file_id[file_id.find('-')+1 : file_id.rfind('-')],
                    file_id + '.wav')

                duration = librosa.core.get_duration(filename=audio_path)

                # Write the metadata to the manifest
                metadata = {
                    "audio_filepath": audio_path,
                    "duration": duration,
                    "text": transcript
                }
                json.dump(metadata, fout)
                fout.write('\n')
                
# Building Manifests
print("******")
train_transcripts = data_dir + '/an4/etc/an4_train.transcription'
train_manifest = data_dir + '/an4/train_manifest.json'
if not os.path.isfile(train_manifest):
    build_manifest(train_transcripts, train_manifest, 'an4/wav/an4_clstk')
    print("Training manifest created.")

test_transcripts = data_dir + '/an4/etc/an4_test.transcription'
test_manifest = data_dir + '/an4/test_manifest.json'
if not os.path.isfile(test_manifest):
    build_manifest(test_transcripts, test_manifest, 'an4/wav/an4test_clstk')
    print("Test manifest created.")
print("***Done***")

# --- Config Information ---#
try:
    from ruamel.yaml import YAML
except ModuleNotFoundError:
    from ruamel_yaml import YAML
config_path = './configs/config.yaml'

if not os.path.exists(config_path):
    # Grab the config we'll use in this example
    BRANCH = 'main'
    url = f'https://raw.githubusercontent.com/NVIDIA/NeMo/{BRANCH}/examples/asr/conf/config.yaml'
    config_dir = f'{data_dir}/configs' 
    Path(f"./configs").mkdir(parents=True, exist_ok=True)
    wget.download(url, f'{config_dir}')

yaml = YAML(typ='safe')
with open(config_path) as f:
    params = yaml.load(f)
print(params)

class LogPerformanceCallback(Callback):

    def __init__(self):
        super().__init__()
        self.start_time = 0.0
        self.last_batch_end_time = 0.0
        self.update_count = 0.0
        self.backward_start_time = 0.0
        self.forward_start_time = 0.0
        self.between_step_time = 0.0

    @rank_zero_only
    def on_train_start(
        self,
        trainer: Trainer,
        pl_module: L.LightningModule,
    ):
        super().on_train_start(trainer, pl_module)
        self.start_time = time.time()
        self.last_batch_end_time = time.time()
        self.between_step_time = time.time()
        print(f'[{dt.utcfromtimestamp(time.time())}] Training start')

    @rank_zero_only
    def on_train_batch_start(self, trainer, pl_module, batch, batch_idx):
        super().on_train_batch_start(trainer, pl_module, batch, batch_idx)
        pl_module.log(
            "performance/between_step_time",
            time.time() - self.between_step_time,
            on_step=True,
            on_epoch=False,
        )
        self.forward_start_time = time.time()

    @rank_zero_only
    def on_before_backward(self, trainer, pl_module, loss):
        super().on_before_backward(trainer, pl_module, loss)
        forward_time = time.time() - self.forward_start_time
        pl_module.log(
            "performance/forward_time",
            forward_time,
            on_step=True,
            on_epoch=False,
        )
        self.backward_start_time = time.time()

    @rank_zero_only
    def on_after_backward(self, trainer, pl_module):
        super().on_after_backward(trainer, pl_module)
        backward_time = time.time() - self.backward_start_time
        pl_module.log(
            "performance/backward_time",
            backward_time,
            on_step=True,
            on_epoch=False,
        )

    @rank_zero_only
    def on_train_epoch_start(self, *args, **kwargs) -> None:
        super().on_train_epoch_start(*args, **kwargs)
        self.update_count = 0.0
        self.start_time = time.time()
        self.last_batch_end_time = time.time()
        self.between_step_time = time.time()
        # print(f'[{dt.utcfromtimestamp(time.time())}] Epoch start')

    @rank_zero_only
    def on_train_epoch_end(self, *args, **kwargs) -> None:
        super().on_train_epoch_start(*args, **kwargs)
        self.update_count = 0.0
        self.start_time = time.time()
        self.last_batch_end_time = time.time()
        self.between_step_time = time.time()
        print(f'\n[{dt.utcfromtimestamp(time.time())}] Epoch end\n')
    
    @rank_zero_only
    def on_train_batch_end(
        self,
        trainer: Trainer,
        pl_module: L.LightningModule,
        outputs: STEP_OUTPUT,
        batch: Any,
        batch_idx: int,
    ):
        super().on_train_batch_end(trainer, pl_module, outputs, batch, batch_idx)
        self.update_count += 1

        # Calculate total elapsed time
        total_elapsed_time = time.time() - self.start_time
        last_elapsed_time = time.time() - self.last_batch_end_time
        self.last_batch_end_time = time.time()

        # Calculate updates per second
        average_updates_per_second = self.update_count / total_elapsed_time
        last_updates_per_second = 1 / last_elapsed_time

        # Log updates per second to wandb using pl_module.log
        pl_module.log(
            "performance/average_updates_per_second",
            average_updates_per_second,
            on_step=True,
            on_epoch=False,
        )
        pl_module.log(
            "performance/last_updates_per_second",
            last_updates_per_second,
            on_step=True,
            on_epoch=False,
        )
        self.between_step_time = time.time()

cb = LogPerformanceCallback()
trainer = pl.Trainer(devices=1, accelerator='gpu', callbacks=cb,
                    log_every_n_steps=10, max_epochs=10)

from omegaconf import DictConfig
params['model']['train_ds']['manifest_filepath'] = train_manifest
params['model']['validation_ds']['manifest_filepath'] = test_manifest
first_asr_model = nemo_asr.models.EncDecCTCModel(cfg=DictConfig(params['model']), trainer=trainer)

# Start training!!!
trainer.fit(first_asr_model)

# Bigger batch-size = bigger throughput
params['model']['validation_ds']['batch_size'] = 16

# Setup the test data loader and make sure the model is on GPU
first_asr_model.setup_test_data(test_data_config=params['model']['validation_ds'])
first_asr_model.cuda()
first_asr_model.eval()

# We will be computing Word Error Rate (WER) metric between our hypothesis and predictions.
# WER is computed as numerator/denominator.
# We'll gather all the test batches' numerators and denominators.
wer_nums = []
wer_denoms = []

# Loop over all test batches.
# Iterating over the model's `test_dataloader` will give us:
# (audio_signal, audio_signal_length, transcript_tokens, transcript_length)
# See the AudioToCharDataset for more details.
for test_batch in first_asr_model.test_dataloader():
        test_batch = [x.cuda() for x in test_batch]
        targets = test_batch[2]
        targets_lengths = test_batch[3]        
        log_probs, encoded_len, greedy_predictions = first_asr_model(
            input_signal=test_batch[0], input_signal_length=test_batch[1]
        )
        # Notice the model has a helper object to compute WER
        first_asr_model.wer.update(predictions=greedy_predictions, predictions_lengths=None, targets=targets, targets_lengths=targets_lengths)
        _, wer_num, wer_denom = first_asr_model.wer.compute()
        first_asr_model.wer.reset()
        wer_nums.append(wer_num.detach().cpu().numpy())
        wer_denoms.append(wer_denom.detach().cpu().numpy())

        # Release tensors from GPU memory
        del test_batch, log_probs, targets, targets_lengths, encoded_len, greedy_predictions

# We need to sum all numerators and denominators first. Then divide.
print(f"WER = {sum(wer_nums)/sum(wer_denoms)}")