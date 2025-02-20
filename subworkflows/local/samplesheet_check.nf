//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    // TO DO:
    // marks can only be H3K4me1, H3K4me3, H3K27me3, H3K9me3 , H3K27ac, H3K36me3, methylation
    // id should be unique
    // seperate bams, beds - keep unique id and can join on common mark, etc
    
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    Channel.fromPath(samplesheet)
        .splitCsv ( header:true, sep:',' )
        .map { create_data_channel(it) }
        .set { ch_data }

    ch_data.filter{ it[1].endsWith('.bam') }.set{ ch_bam }
    // ch_bam.dump(tag: 'bam dump')

    ch_data.filter{ it[1].endsWith('.bed.gz') }.set{ ch_meth }
    // ch_meth.dump(tag: 'meth dump')

    ch_data.filter{ it[1].endsWith('.narrowPeak') }.set{ ch_peak }
    // ch_peak.dump(tag: 'peak dump')

    emit:
    ch_bam
    ch_meth
    ch_peak
}

// Function to get list of [ meta, [ reads ] ]
def create_data_channel(LinkedHashMap row) {
    def allowed_marks = ['H3K27me3', 'H3K4me', 'H3K4me3', 'H3K36me3', 'H3K9me3', 'H3K27ac', 'methylation']
    def meta = [:]

    if (!allowed_marks.contains(row.mark)) {
        exit 1, "ERROR: Invalid mark '${row.mark}'. Allowed values are: ${allowed_marks.join(', ')}"
    }
    if (!file(row.file).exists()) {
        exit 1, "ERROR: Check samplesheet, file does not exist\n${row.fastq_list}"
    }

    meta.id       = row.id
    meta.sample   = row.sample
    meta.mark     = row.mark
    meta.filename = file(row.file).name

    def data = []
        data = [ meta, row.file ]
    return data
}