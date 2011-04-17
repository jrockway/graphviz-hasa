This module lets you generate GraphViz visualizations of your object graphs.  You can use it as a module, or you can just run the included script to get started immediately!


    $ visualize-objects.pl Some::Class Another::Class

By default, this will run `xdot` with the object graph.  But if you
don't have xdot, then it will create a dot file named after the first
class you supply.

If you pipe the output somewhere, no files or programs will be run,
and the dot markup will be printed to stdout:

    $ visualize-objects.pl TinyWeb::User | dot -Tpng -o example.png

This is how I generated the example:

![example!](https://github.com/jrockway/graphviz-hasa/raw/master/example.png)
