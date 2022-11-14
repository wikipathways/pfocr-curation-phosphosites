# pfocr-curation-phosphosites
A curation tool for classifying the contents of Pathway Figure OCR. This special edition of the tool includes features for characterizing the phosphosite content of PFCOR.

## Background
The Pathway Figure OCR project (PFOCR) aims to identify pathway figures from the published literature and extract biological meaning from them. Our pipeline has already screened over 300,000 figures published over the past 27 years and identified  80,000 pathway figures. Millions of genes and hundreds of thousands of chemicals have been extracted from the figures using optical character recognition (OCR) and matched to proper database identifiers (i.e., HGNC and MESH). Read more about the project in [Hanspers et al. 2020](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-020-02181-2), and explore the database at https://gladstone-bioinformatics.shinyapps.io/shiny-25years/.

## Purpose
This repo contains a shiny app that you can run locally to help with classifying the contents of the PFOCR project. This particular version of the tool generates a report offering a count of figures
containing phosphosite information and a count of the number of sites per figure.

## New Curator Training
If this is your first time, go ahead and clone the repo and give the tool a try. By default, the tool is in [training mode](https://github.com/wikipathways/pfocr-curation-phosphosites/blob/main/app.R#L11).

#### Installation
 * Install R
 * Install R Studio
 * Clone this repo
 * Run the app

## How It Works
The tool will read in an RDS of figure metadata to be curated (e.g., pfocr_curating.rds) and compare this against the figures already curated (if any, e.g., pfocr_curated.rds). It will then present the next figure to be curated, displaying editable fields and some helpful button operations. The last of buttons will either save the curated fields, reload the original content, or go back to the previous if you have second thoughts.

![Screenshot](screenshot.png?raw=true "Screenshot")

**Classification buttons**
 * No Phospho - contains no phosphorylations
 * Some Phospho - contains non-specific phosphorylations (e.g., -P) 
 * Phosphosite - contains specific phosphosites (e.g., SER230)
 * Undo - return to previous figure to change classification

