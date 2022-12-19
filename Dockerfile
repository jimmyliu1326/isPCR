FROM rocker/r-ver:4.1.3

RUN apt-get update -y && \
    apt-get install -y libcairo2-dev \
        libxt-dev \
        pandoc \
        libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c( \
                'tidyverse', 'data.table', \
                'argparse'))"

ADD R/ /R/

RUN chmod 777 -R /R