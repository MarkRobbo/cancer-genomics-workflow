#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "fp_filter workflow"
inputs:
    cram:
        type: File
        secondaryFiles: [^.crai]
    reference:
        type: File
        secondaryFiles: [.fai]
    vcf:
        type: File
        secondaryFiles: [.tbi]
    filtered_vcf_basename:
        type: string?
        default: filtered
outputs:
    filtered_vcf:
        type: File
        outputSource: hard_filter/filtered_vcf
steps:
    cram_to_bam:
        run: cram_to_bam.cwl
        in:
            cram: cram
            reference: reference
        out:
            [bam]
    fp_filter:
        run: fp_filter.cwl
        in:
            reference: reference
            bam: cram_to_bam/bam
            vcf: vcf
        out:
            [filtered_vcf]
    fp_bgzip:
        run: ../detect_variants/bgzip.cwl
        in:
            file: fp_filter/filtered_vcf
        out:
            [bgzipped_file]
    fp_index:
        run: ../detect_variants/index.cwl
        in:
            vcf: fp_bgzip/bgzipped_file
        out:
            [indexed_vcf]
    hard_filter:
        run: select_variants.cwl
        in:
            reference: reference
            vcf: fp_index/indexed_vcf
            exclude_filtered: hard_filter_vcf
            output_vcf_basename: filtered_vcf_basename
        out:
            [filtered_vcf]

