# empirical-paper

A project to process, analyze, and interpret data on the changes in
the spatial distribution of deforestation in Borneo as a result of the
2011 moratorium on new deforestation concessions in Indonesia.

## Latest uploaded version

The primary purpose of this project is to analyze and interpret the
spatial distribution of deforestation, and how it changed with the
enactment of Indonesia's 2011 moratorium on new deforestation
concessions.  The latest uploaded version of the write up is below.  The latest version (errors and all) can be found [here](https://github.com/danhammer/empirical-paper/blob/develop/write-up/paper.pdf).

<div><object style="width:420px;height:272px" ><param name="movie" value="http://static.issuu.com/webembed/viewers/style1/v2/IssuuReader.swf?mode=mini&amp;embedBackground=%23000000&amp;backgroundColor=%23222222&amp;documentId=121110200306-a73cccb65e634f2faf87735a68a51652" /><param name="allowfullscreen" value="true"/><param name="menu" value="false"/><param name="wmode" value="transparent"/><embed src="http://static.issuu.com/webembed/viewers/style1/v2/IssuuReader.swf" type="application/x-shockwave-flash" allowfullscreen="true" menu="false" wmode="transparent" style="width:420px;height:272px" flashvars="mode=mini&amp;embedBackground=%23000000&amp;backgroundColor=%23222222&amp;documentId=121110200306-a73cccb65e634f2faf87735a68a51652" /></object><div style="width:420px;text-align:left;"><a href="http://issuu.com/danhammer/docs/sec-11.pdf?mode=window&amp;backgroundColor=%23222222" target="_blank">Open publication</a> - Free <a href="http://issuu.com" target="_blank">publishing</a></div></div>

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
