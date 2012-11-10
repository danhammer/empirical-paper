# empirical-paper

A project to process, analyze, and interpret data on the changes in
the spatial distribution of deforestation in Borneo as a result of the
2011 moratorium on new deforestation concessions in Indonesia.

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

git clone git@github.com:danhammer/empirical-paper.git
cd empirical-paper/

lein do compile :all, uberjar
repl
```

At this point, you will be in a REPL, and can launch a command from
within any available namespace.  Specifically, if you want to restrict
the data set to pixels within Borneo, you can run the `screen-borneo`
function from within the `empirics.core` namespace. 

```clojure
(use 'empirics.core)
(in-ns 'empirics.core)

(let [prob-src (hfs-seqfile (:raw-path seqfile-map))
      static-src (hfs-seqfile (:raw-path seqfile-map))]
  (?- (hfs-seqfile (:prob-path seqfile-map) :sinkmode :replace)
      (screen-borneo prob-src static-src)))
```

This code will screen out all pixels that are not in Borneo, and save
it do a sequence file on S3.

## License

Copyright © 2012

Distributed under the Eclipse Public License, the same as Clojure.
