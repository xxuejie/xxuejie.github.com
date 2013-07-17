---
layout: post
title: "Webruby is now a gem!"
date: 2013-07-17 14:34
comments: true
categories: mruby JavaScript
sharing: false
---

It's been quite some time since I wrote my last post. I've been pretty busy with my work these days, I've also been to Japan for my RubyKaigi 2013 [talk](http://rubykaigi.org/2013/talk/S07). But I managed to finish one feature for webruby, of which I've been dreaming for quite a long long time. Ladies and gentleman, from this time, you can install webruby using the following command:

{% highlight bash %}
$ gem install webruby
{% endhighlight %}

No more boring `git` commands, it is just that simple, webruby is now a [gem](https://rubygems.org/gems/webruby)!

Well, the sad truth is: it is actually not that simple. We need `python2`, `ruby`, `node.js` for this, but I believe you awesome guys or ladies already have these installed, right? The only tricky part is that `LLVM 3.2` is needed to run `emscripten`, with `LLVM 3.3` already released, this can be a little [troublesome](https://github.com/xxuejie/webruby/issues/8). What I suggest is that you can go to [here](http://llvm.org/releases/download.html#3.2), download the binary files for your favourite OS, extract it and define an environment variable `LLVM` containing the `bin` folder of the extracted files. This will be enough to let `emscripten` find `LLVM 3.2`.

With LLVM and webruby installed, we can use the following command to create a new project:

{% highlight bash %}
$ webruby new MyFirstWebrubyProject
{% endhighlight %}

Webruby will create a folder named `MyFirstWebrubyProject` with files you need:

{% highlight bash %}
$ tree MyFirstWebrubyProject

MyFirstWebrubyProject
├── Rakefile
└── app
└── app.rb

1 directory, 2 files
{% endhighlight %}

In `Rakefile`, you can do all the customization for webruby: whether you want to add new mrbgem, whether you want to build as release mode or debug mode, or whether you want to change the entrypoint file. By default, the entrypoint will be `app/app.rb`, [mrubymix](/2013/01/25/introducing-mrubymix/) is used here to solve the difficult `require` part. I know you guys don't like this, but this is the closest solution I could think of. I will keep an eye on thoughts on the Internet, and if I found a nicer way, I will bring your favourite `require` back.

Building is as simple as running `rake`. But keep in mind that if you are running emscripten for the first time on your machine, you may find this:

{% highlight bash %}
$ rake
WARNING: We found out that you have never run emscripten before, since
emscripten needs a little configuration, we will run emcc here once and
exit. Please follow the instructions given by emcc. When it is finished,
please re-run rake.

==============================================================================
Welcome to Emscripten!

This is the first time any of the Emscripten tools has been run.

A settings file has been copied to ~/.emscripten, at absolute path: /Users/rafael/.emscripten

It contains our best guesses for the important paths, which are:

  LLVM_ROOT       = /usr/local/bin
  PYTHON          = /usr/local/bin/python2
  NODE_JS         = /usr/local/bin/node
  EMSCRIPTEN_ROOT = /Users/rafael/.rbenv/versions/2.0.0-p195/lib/ruby/gems/2.0.0/gems/webruby-0.1.1/modules/emscripten

Please edit the file if any of those are incorrect.

This command will now exit. When you are done editing those paths, re-run it.
==============================================================================
{% endhighlight %}

In most cases, emscripten will figure everything out, and you can simple type `rake` again to build your project. I only did this to keep you away from wired behaviours like one of you files are not built correctly.

I feel excited that we can finally avoid the annoying `git` staging areas, what do you guys think?
