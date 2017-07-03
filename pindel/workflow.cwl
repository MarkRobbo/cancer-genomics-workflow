#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "pindel parallel workflow"
requirements:
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement
inputs:
    input1:
        type: File
        secondaryFiles: [".fai"]
    input2:
        type: File
        secondaryFiles: ["^.bai"]
    input3:
        type: File
        secondaryFiles: ["^.bai"]
    input4:
        type: File
    input5:
        type: int
        default: 400
outputs:
    output1:
        type: File
        outputSource: step11/indexed_vcf
        secondaryFiles: [".tbi"]
steps:
    step1:
        run: get_bam_index.cwl
        in:
            bam: input2
        out:
            [bam_index]
    step2:
        run: get_bam_index.cwl
        in:
            bam: input3
        out:
            [bam_index]
    step3:
        run: get_chromosome_list.cwl
        in: 
            interval_list: input4
        out:
            [chromosome_list]
    step4:
        scatter: chromosome
        run: pindel_cat.cwl
        in:
            reference: input1
            tumor_bam: input2
            normal_bam: input3
            tumor_bam_index: [step1/bam_index]
            normal_bam_index: [step2/bam_index]
            chromosome: [step3/chromosome_list]
            insert_size: input5
        out:
            [per_chromosome_pindel_out]
    step5:
        run: cat_all.cwl
        in:
            chromosome_pindel_outs: [step4/per_chromosome_pindel_out]
        out:
            [all_chromosome_pindel_out]
    step6:
        run: grep.cwl
        in: 
           pindel_output: step5/all_chromosome_pindel_out
        out:
           [pindel_head] 
    step7:
        run: somaticfilter.cwl
        in:
            reference: input1
            pindel_output_summary: step6/pindel_head
        out: 
            [vcf]
    step8:
        run: ../detect_variants/bgzip.cwl
        in: 
            file: step7/vcf
        out:
            [bgzipped_file]
    step9:
        run: ../detect_variants/index.cwl
        in:
            vcf: step8/bgzipped_file
        out:
            [indexed_vcf]
    step10:
        run: ../detect_variants/select_variants.cwl
        in:
            reference: input1
            vcf: step9/indexed_vcf
            interval_list: input4
        out:
            [filtered_vcf]
    step11:
        run: ../detect_variants/index.cwl
        in:
            vcf: step10/filtered_vcf
        out:
            [indexed_vcf]
