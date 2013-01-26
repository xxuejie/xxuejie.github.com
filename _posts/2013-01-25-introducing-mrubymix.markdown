---
layout: post
title: "Introducing mrubymix: static require for mruby"
date: 2013-01-25 22:20
comments: true
categories: webruby mruby JavaScript
---

I've been considering a lot about the "require" problem in Webruby. We [know](https://github.com/mruby/mruby/pull/286) that mruby will not have an official `require` function. While it is not so hard to write [one](https://github.com/mattn/mruby-require), we still may not be able to get a consistent API, since all the mrbgems are directly adding modules or classes without needing a `require`. Personally, I think this makes `require` useless. What's more, when targeting an embedded system, is it possible that we will always have a dynamic library loading mechanism? I just don't have the answer.

However, we still need a way to organize the source code. Nowadays we cannot assume that anyone is interested in putting all the source code in one file! One way of solving this is to use `cat` to concatenate all the source files just as what we would do when compiling `mruby` unit tests. However, there's still one problem: you need to maintain the order of concatanation. A simple `cat *.rb > rbcode.rb` will not solve the problem since the order may not be what you want, just imagine if you have a zlib library named `zlib.rb` and many other source files depend on it.

So what we really need here is a utility that can:

1. Combine multiple Ruby source files into one giant file.
2. Maintain a dependency or an order of different files.

I'm not an enthusiast of Rails, but what came to my mind first is the [Rails asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html). It solves exactly the same problem, but on JavaScript or CSS files. So can we borrow the ideas from Rails and use it on Webruby, or even mruby?

Here I created a gem(Ruby gem, not mrbgem) called [mrubymix](https://rubygems.org/gems/mrubymix). It reads a root source file, or an **entrypoint** file, then parses and includes all the other source files `required` by the entrypoint. mrubymix will automatically records the dependency of each file, and only include one source file once, even if it is required by many other file.

Here is an example, supports we have the following entrypoint file, named `app.rb`:

{% highlight ruby %}
#= require aaa
#= require ./foo/bar
puts "This is app.rb!"
{% endhighlight %}

You may notice that the syntax here we use is the same as Rails asset pipeline. This `app.rb` file has two depencencies: `aaa.rb` and `./foo/bar.js`. Two simple rules are used here:

* The suffix `.rb` can be omitted.
* The path of required file is relative to the path of current file

To demostrate how mrubymix resolves multiple dependencies of the same file, suppose `aaa.rb` contains the following content:

{% highlight ruby %}
#= require ./foo/bar
puts "This is aaa.rb!"
{% endhighlight %}

And this is the content of `./foo/bar.rb`:

{% highlight ruby %}
puts "This is foo/bar.rb!"
{% endhighlight %}

We can run the following command to process `app.rb`:

{% highlight bash %}
$ mrubymix app.rb out.rb
{% endhighlight %}

The first argument to mrubymix is the path of the entrypoint file, while the second argument is the path of output file. After running this command, the content of `out.rb` should be:

{% highlight ruby %}
# File: /Users/rafael/develop/tmp/post/foo/bar.rb
puts "This is foo/bar.rb!"

# File: /Users/rafael/develop/tmp/post/aaa.rb
puts "This is aaa.rb!"

# File: /Users/rafael/develop/tmp/post/app.rb
puts "This is app.rb!"

{% endhighlight %}

For each file, mrubymix will first write the full path of the file included as a Ruby comment, then the actual content of the file will be appended. Notice here that all the `require` lines are removed. What's more, even though the file `foo/bar.rb` has been required twice, only one is actually inserted, the inserted location is also the earliest one, which is ahead of all depending source files.

For now, this gem is just reinventing wheels of [sprockets](https://github.com/sstephenson/sprockets), which only deals with JavaScript, CoffeeScript and CSS. One idea would be change this gem to use the parsing part of sprockets, this could bring new features such as `require_tree`, or `require_directory`, etc. But for now, I can live with this simple implementation.

The build process of Webruby has also been [changed](https://github.com/xxuejie/webruby/commit/a730c458e48e7fb2bee8de043929ac732a279f64) to use this small library. Considering the simplicity of building process and the small size of this gem, I just added as a git submodule instead of requiring this gem to be available on your machine. This may provide another reason of maintaining an independent library instead of using sprockets.

I believe this gem is not only helpful for Webruby. Whenever you are using mruby, you need to solve the code organization problem, and this gem can provide an alternative to the regular `require` way:)
