import groovy.time.TimeCategory 
import groovy.time.TimeDuration

process GATK_REALIGNERTARGETCREATOR {
    container "ghcr.io/martinluttap/gatk:3.7-no-entrypoint"

    input: 
        path bams_dir
        val normal_bam_name
        val tumor_bam_name
        path ref_path
    
    output:
        path "realtarget.list", emit: output_intervals
    
    script:
        """
        java -jar /usr/local/bin/gatk.jar -T RealignerTargetCreator -R ${ref_path}/GRCh38.d1.vd1.fa -I ${bams_dir}/${normal_bam_name} -I ${bams_dir}/${tumor_bam_name} -o realtarget.list -nt 64
        """
}

process GATK_INDELREALIGNER {
    container "ghcr.io/martinluttap/gatk:3.7-no-entrypoint"

    input: 
        path bams_dir
        val normal_bam_name
        val tumor_bam_name
        path ref_path
        path target_intervals
    
    output:
        path "${normal_bam_name.take(normal_bam_name.lastIndexOf('.'))}_realn.bam", emit: realigned_normal_bam
        path "${tumor_bam_name.take(tumor_bam_name.lastIndexOf('.'))}_realn.bam", emit: realigned_tumor_bam

    script:
        """
        java -jar /usr/local/bin/gatk.jar -T IndelRealigner -R ${ref_path}/GRCh38.d1.vd1.fa -targetIntervals ${target_intervals} -I ${bams_dir}/${normal_bam_name} -I ${bams_dir}/${tumor_bam_name} --nWayOut "_realn.bam"
        """
}

process GATK_MUTECT2 {
    container "ghcr.io/martinluttap/gatk:4.2.4.1-no-entrypoint"

    input: 
        path normal_bam
        path tumor_bam
        path ref_path
    
    script:
        """
        java -jar /usr/local/bin/gatk.jar Mutect2 --java-options "-XX:ParallelGCThreads=64" --native-pair-hmm-threads 64 -R ${ref_path}/GRCh38.d1.vd1.fa -I ${normal_bam} -I ${tumor_bam} -O somatic.vcf.gz --java-options "-XX:ParallelGCThreads=64" --native-pair-hmm-threads 64
        """
}

process GATK_MUTECT2_2 {
    container "ghcr.io/martinluttap/gatk:4.2.4.1-no-entrypoint"

    input: 
        path normal_bam
        path tumor_bam
        path ref_path
    
    script:
        """
        java -jar /usr/local/bin/gatk.jar Mutect2 --java-options "-XX:ParallelGCThreads=64" --native-pair-hmm-threads 64 -R ${ref_path}/GRCh38.d1.vd1.fa -I ${normal_bam} -I ${tumor_bam} -O somatic.vcf.gz  
        """
}


Date loadStart = new Date()
println ("Data loading started ...")

/* Reference files */
REF_PATH = params.ref_dir
ref_fa = REF_PATH + '/GRCh38.d1.vd1.fa'
ref_amb = REF_PATH + '/GRCh38.d1.vd1.amb'
ref_ann = REF_PATH + '/GRCh38.d1.vd1.ann'
ref_bwt = REF_PATH + '/GRCh38.d1.vd1.bwt'
ref_fai = REF_PATH + '/GRCh38.d1.vd1.fai'
ref_pac = REF_PATH + '/GRCh38.d1.vd1.pac'
ref_sa = REF_PATH + '/GRCh38.d1.vd1.sa'
ref_dict = REF_PATH + '/GRCh38.d1.vd1.dict'
ref_known_sites = REF_PATH + '/dbsnp_144.hg38.vcf.gz'
ref_known_sites_tbi = REF_PATH + '/dbsnp_144.hg38.vcf.gz.tbi'

/* Input files */
READ_PATH = params.read_dir + "/synthetic/"
tumor_bam = Channel.fromPath(READ_PATH + 'sim1-50mb_sorted_tag.bam')
normal_bam = Channel.fromPath(READ_PATH + 'sim2-50mb_sorted_tag.bam')
tumor_bam_name = 'sim1-50mb_sorted_tag.bam'
normal_bam_name = 'sim2-50mb_sorted_tag.bam'

// READ_PATH = params.read_dir + "/tumor-normal"
// tumor_bam = Channel.fromPath(READ_PATH + 'COLO829_illumina_tumor_1_100000_1000000.bam')
// normal_bam = Channel.fromPath(READ_PATH + 'COLO829_illumina_normal_1_100000_1000000.bam')
// tumor_bam_name = 'COLO829_illumina_tumor_1_100000_1000000.bam'
// normal_bam_name = 'COLO829_illumina_normal_1_100000_1000000.bam'

realigned_normal_bam = Channel.fromPath(READ_PATH + 'sim1-50mb_sorted_tag_realn.bam')
realigned_tumor_bam = Channel.fromPath(READ_PATH + 'sim2-50mb_sorted_tag_realn.bam')


workflow {
    // GATK_REALIGNERTARGETCREATOR(
    //     READ_PATH,
    //     normal_bam_name,
    //     tumor_bam_name,
    //     REF_PATH,
    // )
    // GATK_INDELREALIGNER(
    //     READ_PATH,
    //     normal_bam_name,
    //     tumor_bam_name,
    //     REF_PATH,
    //     GATK_REALIGNERTARGETCREATOR.out.output_intervals
    // )
    GATK_MUTECT2(
        realigned_normal_bam,
        realigned_tumor_bam,
        REF_PATH
    )
    GATK_MUTECT2_2(
        realigned_normal_bam,
        realigned_tumor_bam,
        REF_PATH
    )
}
