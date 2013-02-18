---
layout: post
title: "Finally it's here: Webruby 1-2-3 tutorial"
date: 2013-01-09 12:29
comments: true
categories: webruby mruby JavaScript
---

**Update**: I've changed the API a little bit. Please check this [post](/2013/01/15/o2-mode/) for the latest API. I decided to keep this post unchanged so you can see both versions. Feel free to leave a comment if you belive the old one is better:)

Lately some people have been asking me to write a tutorial on how to use Webruby. Sorry, guys. I was having a lot of fun writing this stuff but I forgot to bring these fun to you. Now the tutorial on Webruby is finally here:)

The final result of this tutorial looks like this:

<img src="http://i.minus.com/i6XdI9H3mNcUQ.png" />

You can also find a live demo at [here](/projects/webruby-tutorial/). The demo page uses jQuery to insert \<p\> tags from Ruby side. This is a boring and pretty stupid demo, but it at least shows how to execute Ruby code and how to call JavaScript code from Ruby side, so I wish you wouldn't feel too bored. Well, let's get started:)

## First question: where do I put my Ruby source code?

Before everything starts, we need a place to keep and load our Ruby source code. Webruby now supports 3 kinds of source code loading methods:

* All the source code in `app` folder of Webruby will be compiled and attached in the `mruby.js` file automatically. Then we can use `WEBRUBY.run` to load this part of source code.

* You can pre-compile the Ruby source code, pass the generated mruby bytecodes to the browser side either by attached JavaScript file or XMLHttpRequest, and use `WEBRUBY.run_bytecode` to execute the bytecode directly. With this method, you can get the flexibility of loading code on the fly, while avoiding parsing Ruby source code at the browser side(and the whole parsing part can be avoided in `mruby.js` file).

* And of course, you can use `WEBRUBY.run_source` to parse and execute Ruby code directly.

Webruby allows you to specify the loading modes you will use when compiling, this can help reduce the size of `mruby.js` file: if you do not need to parse Ruby source code on the fly, you wouldn't need all the parsing code in the generated `mruby.js` file, and if you only execute source code from `app` folder, modern optimizers may take advantage of that to further reduce the file size. Please refer to `rakelib/functions.rb` for how to specify supported loading modes. In this tutorial, we will use the default loading modes, which will support all 3 kinds of loading methods. And we will show how to load Ruby source code using `WEBRUBY.run` and `WEBRUBY.run_source`. The second method describes above is a little bit of complicated(since mruby has multiple versions of bytecode), I will describe it in another post(maybe with specialized bytecode generation tools) later.

## Okay, I got that. But how to run this stuff exactly?

Now we've got all the backgrounds needed, let's walk through the developing process step by step.

### Environment setup

I assure you that this is easy to do. Just clone the [project](https://github.com/xxuejie/webruby] from Github and setup submodules:

{% highlight bash %}
$ git clone git://github.com/xxuejie/webruby.git
$ git submodule init && git submodule update
{% endhighlight %}

And do remember one thing: webruby uses emscripten, and emscripten uses LLVM internally. So you may also need to install LLVM:

{% highlight bash %}
$ brew install llvm --with-clang
{% endhighlight %}

Note this is the Mac-with-homebrew way of installing LLVM. If you know how to install LLVM 3.2 on Linux/Windows, I will really appreciate it if you can comment below, I will update this post accordingly.

**Update**: Thanks to [Reed](https://github.com/reedlaw) for pointing out, actually you can just go to <http://llvm.org/releases/download.html>, download and extract the pre-compiled binary for your platform, change the value of `LLVM_ROOT` in your `~/.emscripten` file to match the bin directory of your LLVM installation. You are then good to go!

This is almost it! I guess I may assume that most of you have Ruby and node.js installed already. But if you are not so convinced, you can run the mruby unit tests in webruby environment:

{% highlight bash %}
# in mruby folder
$ rake mrbtest
# building output omitted
node /Users/rafael/develop/webruby/build/mrbtest.js
mrbtest - Embeddable Ruby Test

This is a very early version, please test and report errors.
Thanks :)

..............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................
Total: 510
OK: 510
KO: 0
Crash: 0
Time: 9.389 seconds
{% endhighlight %}

If you can see this, everything is fine:)

### GEM setup

Webruby is designed in a way that the core project just contains build scripts and a very small yet required driver code. The rest parts are in separate projects(organized as [mrbgems](http://mruby.sh/201212101231.html)). The idea here is that your final `mruby.js` file does not to contain the part that you will not use. So the default build only contains a mruby runtime. In this demo we will need JavaScript calling support, which is provided by [mruby-js](https://github.com/xxuejie/mruby-js).

The latest mruby supports using mrbgem directly from a git repository, so all you need to do here is uncomment Line #32 in `build_config.rb`. And make it look like this:

{% highlight ruby %}
# JavaScript calling interface
conf.gem :git => 'git://github.com/xxuejie/mruby-js.git', :branch => 'master' # This is the line to uncomment!
{% endhighlight %}

Notice that if you have run `mrbtest` before uncommenting this line, you need to run `rake clean` to cleanup everything and do a full rebuild. This is due to that the gem settings have changed.

### Writing Webruby code

Now we can actually start writing Ruby code. First we will try the first loading method: all the source code in `app` folder of webruby will be compiled and then attached in the `mruby.js` file. So feel free to add or change any file in the folder, but please do remember to add `.rb` suffix.

A special file named `app.rb` will be compiled at last, it serves as the entrypoint(or so-called "main" file). For our simplest demo, we will just code in this file. Now you can bring out your favourite code editor and change the content of this file to:

{% highlight ruby %}
# This is the entrypoint file for webruby

# get window object
root_object = MrubyJs.get_root_object

# get jQuery selected object
container = root_object.call("$", "#container")

# appends <p> tag
container.call("append", "<p>This is inserted in Webruby using WEBRUBY.run()!</p>")
{% endhighlight %}

There is only one method in module `MrubyJS`: `get_root_object`. It would return the `window` object for a browser environment, or the `global` object when running in node.js. The returned object is of class `JsObject`, it is a wrapper over the actual object at JavaScript side. With its `call` function, you can make a call to a JavaScript function, the first argument is the function name, while the rest arguments are all passed to the JavaScript function.

`JsObject` also comes with `call_constructor` function for making a new call, and `get` for getting a field value from an object. Note that `mruby-js` is still under development, function and array passing support is still lacking, and the APIs are subject to change. I will try my best to keep here updated, but please always use the source code as the answer if you find a disagreement.

Now you can compile webruby using `rake`, if everything works well(it should), you can find a `mruby.js` file in `build` folder.

### HTML skeleton

Node.js is great for debugging, but I believe most of you want to use webruby in a browser enviroment. We also need an HTML skeleton for loading our generated JS file.

Here's a sample skeleton: note that this only serves as a sample, and I believe all of you can write a much better skeleton within seconds. But for now, please bear with this dumb one:

{% highlight html %}
<!DOCTYPE html>
<html>
  <head>
    <title>Webruby tutorial</title>
    <script src="http://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
    <script src="mruby.js"></script>
  </head>
  <body>
    <h1>This is a skeleton for Webruby tutorial!</h1>
    <div id="container"></div>
    <script>
      $(document).ready(function() {
        var mrb = WEBRUBY.open();

        /* Runs embedded source code in mruby.js file. */
        WEBRUBY.run(mrb);

        WEBRUBY.close(mrb);
      });
    </script>
  </body>
</html>
{% endhighlight %}

Put this html file in the same folder with `mruby.js` file and open it with a modern browser, you can see an initial result:)

### Loading Ruby source code on the fly

By changing the value of environment variable `LOADING_MODE`, you can actual customize the loading methods you want to support. For example, the following line can be used to only allow for running attached Ruby code compiled from `app` folder:

{% highlight bash %}
$ LOADING_MODE=0 rake
{% endhighlight %}

If you have been following this post, then your `mruby.js` must have already contained parsing code. Otherwise you may want to use following command to rebuild the JS file:

{% highlight bash %}
$ LOADING_MODE=0 rake
{% endhighlight %}

The Ruby code can thus be put in a JavaScript string, which may comes from other JavaScript file or XMLHttpRequest. In our demo we just hardcoded it in a string for simplicity:

{% highlight html %}
<!DOCTYPE html>
<html>
  <head>
    <title>Webruby tutorial</title>
    <script src="http://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
    <script src="mruby.js"></script>
  </head>
  <body>
    <h1>This is a skeleton for Webruby tutorial!</h1>
    <div id="container"></div>
    <script>
      /* Inline source code, in practice you may want to get this from
       * an XMLHttpRequest.
       */
      var src = "MrubyJs.get_root_object.call('$', '#container')" +
        ".call('append', '<p>This is inserted in Webruby using " +
        "WEBRUBY.run_source()!</p>')";

      $(document).ready(function() {
        var mrb = WEBRUBY.open();

        /* Runs embedded source code in mruby.js file. */
        WEBRUBY.run(mrb);

        /* Parses and executes Ruby code on the fly. */
        WEBRUBY.run_source(mrb, src);

        WEBRUBY.close(mrb);
      });
    </script>
  </body>
</html>
{% endhighlight %}

Now it looks just like what is shown in the demo. You can also use Closure Compiler to strip the size of generated JS file if you like, but please keep in mind that only simple optimization works for now, the advanced option still needs a little tweaking. On my machine, with a simple optimization the size of the JS file can be reduced from 4.2MB to 1.5MB.

## Conclusion

It really feels nice to finally have something for everyone to use:) I've had a lot of fun and I will be continue maintaining this. Of course this is not fit for everyone's project, even after optimization there's a 1.5MB JS file to load. For now I guess the most suitable use case will be Web games or single page apps. This is why I'm also working on an OpenGL ES 2.0 binding. Anyway, I wish all of you had fun playing with webruby, just like I had fun developing this:)
