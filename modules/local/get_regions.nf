process GET_REGIONS {
        label 'process_medium'
        container "nidhidav/nf-chromhmm:v1"

        input:
        path(regions)

        output:
        path ("regions/")          , emit: regions
        path ("regions_200_bp.bed"), emit: regions_200_bp

        script:
        chr = params.XY ? "{1..22} X Y" : "{1..22}"
        """
        mkdir regions
        awk -F'\\t' 'BEGIN {OFS="\\t"} {print \$1, 0, \$2}' $regions > bedtools_input.bed &&
        bedtools makewindows -b bedtools_input.bed -w 200 | awk '{if (\$3 - \$2 == 200) print \$0}' > regions_200_bp.bed &&
        for i in $chr; do
            cat regions_200_bp.bed | grep -w chr\$i > regions/chr\$i.regions.bed
        done
        """
}
