---
layout: post
title: "Happy birthday Ruby! Let's get lost in the JavaScript world!"
date: 2013-02-24 9:59
comments: true
categories: webruby mruby JavaScript Ruby
---

Happy birthday Ruby! It's 24th in the US now, while it is still 24th in Japan. So it is neither too early nor to late:) It is also a perfect chance(and a happy coincidence, I didn't plan to release on this day, it just happens) to show you some of my latest work. The result looks like this:

<img src="http://i.minus.com/ibckiVXlJnwo1t.png" />

A live demo is at [here](http://qiezi.me/projects/webgl/geometries.html). This is the WebGL geometries example at [here](http://mrdoob.github.com/three.js/examples/webgl_geometries.html) provided in the [three.js](http://mrdoob.github.com/three.js/) repository. While the original example is written in JavaScript, I took some time(actualy less than an hour) to port it to Ruby. The Ruby source code and original JavaScript source code are at [here](https://gist.github.com/xxuejie/5023857). However, feel free to dig into your favourite developer tools for the demo listed above, since the Ruby code is stored in a separate [file](http://qiezi.me/projects/webgl/ruby/app.rb), fetched using Ajax and parsed on the fly.

From a comparison of the two versions of source code you can see that a lot of things can be achieved purely in the Ruby side:

* Fetch the fields of a JavaScript object using both '.' syntax and '[]' syntax
* Call a JavaScript function using either normal method or new call
* Pass Ruby strings, arrays and hashes as arguments to the JavaScript functions
* Use either JavaScript functions or Ruby Procs as callback functions

Basically most of the things you normally do in JavaScript can be done entirely in Ruby. However, there're still some syntax differences:

* While you can use `console.log("Log message!")` to call a JavaScript function, if you want to invoke a function with no arguments, you either need to use `console.log.invoke` or `console.log[]`. This is because Ruby does not distinguish between `console.log` and `console.log()`
* For new call, instead of `new bar()`, we need to use `bar.invoke_new`, since I haven't found a good way to implement `new` function. Maybe I need to check rspec for inspiration-\_-
* You can create a variable that caches a function: such as:

{% highlight ruby %}
object_create_func = $three.SceneUtils.createMultiMaterialObject
{% endhighlight %}

  However, to invoke this function, you need to use following syntax:

{% highlight ruby %}
object = object_create_func[$three.CubeGeometry.invoke_new(100, 100, 100, 4, 4, 4), materials]
{% endhighlight %}

  This is now only a temporarily solution, I may find a way to work around this.

* Suppose you want to call a `set` function on an object `foo`, you cannot directly do a `foo.set(1)`, since `set` is already used in Ruby side, what you can do here is one of the following solutions:

{% highlight ruby %}
foo.call(:set, 1)
# or
foo[:set].invoke(1)
{% endhighlight %}

* When adding Ruby Procs as callback functions, you can either directly create a proc:

{% highlight ruby %}
p = Proc.new {
 puts "Resize occurs!"
}
$window.addEventListener('resize', p, false)
{% endhighlight %}

  You can also use existing functions as callbacks, but do remember you need to use the following syntax:

{% highlight ruby %}
def onResize
 puts "Resize occurs!"
end
$window.addEventListener('resize', :onResize.to_proc, false)
{% endhighlight %}

  While we still use a symbol to represent a function, `to_proc` must be invoked to tell webruby that we want to use the actual function, not the `onResize` string.

* Do remember that in current implementation of webruby, you only have the precision of float, not double. So the range that can be expressed in a number is a little limited. I will check later if we can work this around.

And there's one more TODO task: currently you cannot pass arguments to a callback function using a Ruby proc. For example, if you add arguments to `window.setInterval`, they are not passed back to your Ruby Proc. I will work on this in the next few days(but not today, I have some stupid homework to finish today-\_-).

Although we have a few limitations or rules to keep in mind, I do think we now have a almost complete JavaScript calling interface:) Now we have a whole lot of existing JavaScript libraries that we can take advantage of, including [three.js](http://mrdoob.github.com/three.js/), the yet-to-release [famo.us](http://famo.us/) engine and [WebAudio.js](http://jeromeetienne.github.com/webaudio.js/), etc. We may even take advantage of the WebWorker API for multi-threading! I must admit that I'm a little behind schedule for my [OpenGL ES binding](https://github.com/xxuejie/mruby-gles) project, but since we have three.js now, we can already create awesome Web projects:) Anyway, I will come back to create a complete OpenGL ES binding implemention.

Ruby: will you love your new JavaScript house in the next 20 years? I do wish you enjoy it!
