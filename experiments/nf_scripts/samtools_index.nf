import groovy.time.TimeCategory 
import groovy.time.TimeDuration

TOOL_PATH = params.tool_dir + "samtools_index.nf"

include { SAMTOOLS_INDEX_NO_LIMIT as SAMTOOLS_INDEX1 } from TOOL_PATH
include { SAMTOOLS_INDEX_NO_LIMIT as SAMTOOLS_INDEX2 } from TOOL_PATH

BAM_PATH = params.read_dir + "/bams/1500MB/SRR062634_1500MB_sorted.bam"

Date loadStart = new Date()
println ("Data loading started ...")
bam_file = Channel.fromPath(BAM_PATH)

workflow {
    bam_file.view {
        "Input files: ${it}, num_files=${it.size()}"
    }.subscribe {
        Date loadEnd = new Date()

        TimeDuration td = TimeCategory.minus(loadEnd, loadStart)

        def logFile = new File("LoadDuration.txt")
        logFile.delete()
        logFile.append(td)
        println ("Loading done! Took " + td)
    }
    SAMTOOLS_INDEX1(
        bam_file
    )
    SAMTOOLS_INDEX2(
        bam_file
    )
}