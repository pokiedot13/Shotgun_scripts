#!/bin/bash
#SBATCH --job-name=metaphlanshotgun
#SBATCH --partition=cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --mail-type=END
#SBATCH --mail-user=alr34@kent.ac.uk
#SBATCH --output=/home/alr34/slurm/logs/%j-metaphlanshotgun.out
#SBATCH -p biosoc2

source ~/anaconda3/etc/profile.d/conda.sh
conda activate metaphlan_env

metaphlan --install --index mpa_vOct22_CHOCOPhlAnSGB_202403

humann_databases  --download chocophlan       full  humann_dbs/
humann_databases  --download uniref           full  humann_dbs/
humann_databases  --download utility_mapping  full  humann_dbs/

conda deactivate
