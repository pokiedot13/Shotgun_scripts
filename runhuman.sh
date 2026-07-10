#!/bin/bash
#SBATCH --job-name=humann_prejba
#SBATCH --array=0-50%5
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH -p biosoc2,cpu
#SBATCH --output=/home/alr34/slurm/logs/%A_%a-humann.out
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=alr34@kent.ac.uk

set -euo pipefail

source ~/anaconda3/etc/profile.d/conda.sh
conda activate metaphlan_env

PROJECT=PREJBA
READ_DIR=~/blasto_meta/processed/${PROJECT}
META_DIR=~/blasto_meta/metaphlan_results/${PROJECT}
OUTDIR=~/blasto_meta/humann_results/${PROJECT}

mkdir -p "$OUTDIR"

mapfile -t SAMPLES < <(
    ls "${READ_DIR}"/*_R1.fastq.bz2 2>/dev/null |
    sed 's/_R1.fastq.bz2//' |
    sort
)

if [ "$SLURM_ARRAY_TASK_ID" -ge "${#SAMPLES[@]}" ]; then
    echo "Index $SLURM_ARRAY_TASK_ID out of range, skipping"
    exit 0
fi

SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID]}
BASE=$(basename "$SAMPLE")

R1="${SAMPLE}_R1.fastq.bz2"
R2="${SAMPLE}_R2.fastq.bz2"
UN="${SAMPLE}_UN.fastq.bz2"
PROFILE="${META_DIR}/${BASE}_profile.txt"

if [ ! -s "$R1" ] || [ ! -s "$R2" ]; then
    echo "[SKIP] Missing R1 or R2 for $BASE"
    exit 0
fi

if [ ! -s "$PROFILE" ]; then
    echo "[SKIP] Missing MetaPhlAn profile for $BASE"
    echo "Looked for: $PROFILE"
    exit 0
fi

if [ -s "${OUTDIR}/${BASE}/genefamilies.tsv" ]; then
    echo "[SKIP] HUMAnN already done for $BASE"
    exit 0
fi

echo "Running HUMAnN on $BASE"

WORKDIR="${SLURM_TMPDIR:-${TMPDIR:-$OUTDIR}}"
TMP_FASTQ="${WORKDIR}/${BASE}.fastq.gz"

if [ -s "$UN" ]; then
    bzcat "$R1" "$R2" "$UN" | gzip > "$TMP_FASTQ"
else
    bzcat "$R1" "$R2" | gzip > "$TMP_FASTQ"
fi

humann \
    --input "$TMP_FASTQ" \
    --taxonomic-profile "$PROFILE" \
    --output "${OUTDIR}/${BASE}" \
    --threads "${SLURM_CPUS_PER_TASK}"

rm -f "$TMP_FASTQ"

echo "Finished $BASE"

conda deactivate
