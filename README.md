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

Because pictures are fun, here's what Bread::Board::Container looks
like:

![example2!](https://github.com/jrockway/graphviz-hasa/raw/master/example2.png)

Finally, you can write your own introspectors and use those to produce
the graphs.  Here, we use `GraphViz::HasA::Introspect::IsA` to get isa
and does relationships along with the has a graph:

![example3!](https://github.com/jrockway/graphviz-hasa/raw/master/example3.png)

This lets you see that all those parent links come from
Bread::Board::Traversible, which everything `DOES`.
