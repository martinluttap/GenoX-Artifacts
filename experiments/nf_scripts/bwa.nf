import groovy.time.TimeCategory 
import groovy.time.TimeDuration

TOOL_PATH = params.tool_dir + "bwa.nf"

include { BWA_NO_LIMIT as BWA1 } from TOOL_PATH
include { BWA_NO_LIMIT as BWA2 } from TOOL_PATH
include { BWA_NO_LIMIT as BWA3 } from TOOL_PATH
include { BWA_NO_LIMIT as BWA4 } from TOOL_PATH

REF_PATH = params.ref_dir
ref_fa = Channel.fromPath(REF_PATH + '/*.fa')
ref_amb = Channel.fromPath(REF_PATH + '/*.amb')
ref_ann = Channel.fromPath(REF_PATH + '/*.ann')
ref_bwt = Channel.fromPath(REF_PATH + '/*.bwt')
ref_fai = Channel.fromPath(REF_PATH + '/*.fai')
ref_pac = Channel.fromPath(REF_PATH + '/*.pac')
ref_sa = Channel.fromPath(REF_PATH + '/*.sa')
ref_dict = Channel.fromPath(REF_PATH + '/*.dict')

num_threads = params.num_threads
READ_PATH = params.read_dir + "/SRR24039108"

Date loadStart = new Date()
println ("Data loading started ...")
fastq_pair = Channel.fromFilePairs(READ_PATH + '/*_{1,2}.fastq', flat: true)
                    .splitFastq(by: 40000000, limit: 40000000, pe:true, file: true)

fastq_pair2 = Channel.fromFilePairs(READ_PATH + '/*_{1,2}.fastq', flat: true)
            .splitFastq(by: 250000, limit:250000, pe:true, file: true)

workflow {
    fastq_pair.view {
        "Paired FASTQ: ${it}"
    }.subscribe {
        Date loadEnd = new Date()

        TimeDuration td = TimeCategory.minus(loadEnd, loadStart )

        def logFile = new File("LoadDuration.txt")
        logFile.delete()
        logFile.append(td)
        println ("Loading done! Took " + td)
    }
    BWA1(
        fastq_pair, ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    )
    // BWA2(
    //     fastq_pair, ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    // )
    // BWA3(
    //     fastq_pair, ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    // )
    // BWA4(
    //     fastq_pair, ref_fa, ref_amb, ref_ann, ref_bwt, ref_fai, ref_pac, ref_sa, ref_dict
    // )

}
