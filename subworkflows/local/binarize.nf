include { BINARIZE_BAM           } from '../../modules/local/binarize_bam.nf'
include { BINARIZE_BED           } from '../../modules/local/binarize_bed.nf'
include { BINARIZE_METH          } from '../../modules/local/binarize_meth.nf'
include { MERGE_BINARIES         } from '../../modules/local/merge_binaries.nf'
include { BAM_TO_BED             } from '../../modules/local/bam_to_bed.nf'

workflow BINARIZE {
    take:
        ch_bam
        ch_peak
        ch_meth
        regions
        regions_200_bp
        bam_to_bed

    main:
        //
        // MODULE: binarize bam
        //
        ch_bam
        .map { meta, file -> [meta.sample, meta, file] }
        .groupTuple()
        .map { sample, metaList, _ ->
            def lines = metaList.collect { meta -> "${meta.sample}\t${meta.mark}\t${meta.filename}" }
            return [ "${sample}_bam_mark_file.txt", lines.join('\n') + '\n' ]
        }
        .collectFile { fileName, content -> [ fileName, content ] }
        .map { file -> [file.baseName.tokenize("_")[0], file] }
        .set { bam_cell_mark_files }

        ch_bam
        .map { meta, file -> [meta.sample, file]}
        .groupTuple()
        .set { grouped_bams }

        binarize_bam_input = bam_cell_mark_files.combine(grouped_bams, by: 0)
        BINARIZE_BAM(binarize_bam_input)

        //
        // MODULE: bam to bed
        //
        if(bam_to_bed) {
            ch_bam
            .map { meta, file -> [meta.id, meta, file] }
            .map { id, meta, _ ->
                def lines = "${meta.id}\t${meta.mark}\t${meta.filename}"
                return [ "${id}.bam_mark_file.txt", lines + '\n' ]
            }
            .collectFile { fileName, content -> [ fileName, content ] }
            .map { file -> [file.baseName.tokenize(".")[0], file] }
            .set { bamtobed_cellmarkfiles }

            ch_bam
            .map{meta, file -> [meta.id, file]}
            .combine(bamtobed_cellmarkfiles, by: 0)
            .set{ch_bam_to_bed}

            BAM_TO_BED(ch_bam_to_bed, regions)
        }

        //
        // MODULE: binarize bed
        //
        ch_peak
        .map { meta, file -> [meta.sample, meta, file] }
        .groupTuple()
        .map { sample, metaList, _ ->
            def lines = metaList.collect { meta -> "${meta.sample}\t${meta.mark}\t${meta.filename}" }
            return [ "${sample}_peak_mark_file.txt", lines.join('\n') + '\n' ]
        }
        .collectFile { fileName, content -> [ fileName, content ] }
        .map { file -> [file.baseName.tokenize("_")[0], file] }
        .set { bed_cell_mark_files }

        ch_peak
        .map { meta, file -> [meta.sample, file]}
        .groupTuple()
        .set { grouped_beds }

        binarize_bed_input = bed_cell_mark_files.combine(grouped_beds, by: 0)
        BINARIZE_BED(binarize_bed_input)

        // 
        // MODULE: binarize meth
        //
        BINARIZE_METH(ch_meth, regions_200_bp)

        //
        // MODULE: merge binaries
        //
        merged_input = BINARIZE_BAM.out.bam.join(BINARIZE_BED.out.bed, by: 0).join(BINARIZE_METH.out.meth, by: 0)
        MERGE_BINARIES(merged_input)

    emit:
        merged_binaries = MERGE_BINARIES.out.merged_binary
        bam_binaries = BINARIZE_BAM.out.bam
        bed_binaries = BINARIZE_BED.out.bed
        meth_binaries = BINARIZE_METH.out.meth
        bam_to_bed_output = bam_to_bed ? BAM_TO_BED.out.bed : null
}