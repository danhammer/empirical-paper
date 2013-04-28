# empirical-paper

A project to process, analyze, and interpret data on the changes in
the spatial distribution of deforestation in Borneo as a result of the
2011 moratorium on new deforestation concessions in Indonesia.

## Latest write-up

The primary purpose of this project is to analyze and interpret the
spatial distribution of deforestation, and how it changed with the
enactment of Indonesia's 2011 moratorium on new deforestation
concessions.  The latest version of the paper (errors and all) can be
found
[here](https://github.com/danhammer/empirical-paper/blob/develop/write-up/paper.pdf).

## Computing outline

The data processing is, unfortunately, split into three broad parts
due to the relative strengths of Clojure, R, and Stata.  

1. The raw time series data is screened and processed on a Hadoop
cluster using the `process-borneo` function in the `empirics.core`
namespace.  The details for processing can be found in the following
*Notes* section within the readme.  The output is stored on S3 as a
tab-delimited text file, where each entry is a separate deforestation
alert with the appropriate metadata.

2. The hits are then clustered using the hierarchical clustering
algorithm in Stata.  This is an incredibly inefficient way to find the
clusters; but the Stata implementation is stable and can be run on a
remote server.  It takes many days to run the clustering algorithm for
Borneo for all periods.  The output is saved as a series of separate
files, one for each interval.

3. The graphs and and analysis are done in R, making use of its
graphing libraries and LaTeX export options.  These graphs are
imported into the org-mode write-up, which can be compiled to TeX or
HTML, and then into a PDF.

## Notes

This project makes use of the
[`lein-emr`](https://github.com/dpetrovics/lein-emr) project.  To
start the cluster for this project, you'll first need to install
[Leinigen](https://github.com/technomancy/leiningen) and then type the
following at the command line:

```bash
lein emr -n "emp" -t "large" -s 10 -b 0.2 -m 4 -r 2 -bs bsaconfig.xml 
```

where `bsaconfig.xml` is a configuration script, as described in the
`lein-emr` readme.  Once the cluster is properly bootstrapped and
running, you will need to run the following commands in sequence:

```bash
curl https://raw.github.com/technomancy/leiningen/preview/bin/lein > ~/bin/lein
chmod 755 ~/bin/lein

git clone git@github.com:reddmetrics/forma-clj.git
cd forma-clj
lein do compile :all, install

cd
git clone git@github.com:danhammer/empirical-paper.git
cd empirical-paper/

lein do compile :all, uberjar

repl
```

Or this:

```bash
git clone git://github.com/reddmetrics/forma-clj.git;
cd forma-clj;
git checkout feature/rollback-gadm;
cd ../bin;
wget https://raw.github.com/technomancy/leiningen/preview/bin/lein;
chmod u+x lein;
./lein;
cd ..;
git clone git://github.com/nathanmarz/cascalog.git;
cd cascalog;
lein sub install;
cd ..;
cd forma-clj;
uj;
lein install;
cd ..;
git clone git://github.com/danhammer/empirical-paper.git;
cd empirical-paper;
uj;
```

At this point, you will be in a REPL, and can launch a command from
within any available namespace.  Specifically, if you want to restrict
the data set to pixels within Borneo, you can run the `screen-borneo`
function from within the `empirics.core` namespace. 

```clojure
(use 'empirics.core)
(in-ns 'empirics.core)

(process-borneo)
```

Alternatively, you can run the processing directly from the instance
command line on the master node:

```bash
hadoop jar /home/hadoop/empirical-paper/target/empirics-0.1.0-SNAPSHOT.jar empirics.core.process-borneo
```

This code will screen out all pixels that are not in Borneo, and save
it do a sequence file on S3.  The custom `repl` command will put you
into a separate screen, which you can detach from once the Hadoop job
has started using the key command `C-a d`.  You can reattach with
`screen -rr`.  

Once the job is running, you can check on it in the browser by
entering the DNS followed by `:9100`.  For example:

```bash
ec2-54-242-148-62.compute-1.amazonaws.com:9100
```

## License

Copyright © 2012

Distributed under the Eclipse Public License, the same as Clojure.
