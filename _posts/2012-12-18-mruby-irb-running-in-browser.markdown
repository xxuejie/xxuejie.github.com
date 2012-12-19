---
layout: post
title: "mruby irb now runs in a browser"
date: 2012-12-18 21:57
comments: true
categories: mruby JavaScript
---
After some time's work, now I finally got a working irb for mruby. I'm such a lazy guy so you may already seen the demo from [this](https://twitter.com/kripken/status/281199267350212609), [this](https://twitter.com/yukihiro_matz/status/281187882213982208) or [this](https://twitter.com/defmacro/status/281150651319332865). Anyway, for those of you who didn't see it, the demo is at [here](qiezi.me/projects/mruby-web-irb/mruby.html).

With all the work in [webruby](https://github.com/xxuejie/webruby), actually it is not so hard to implement this. However, there are still two things I want to write down here as notes.

##Passed-by-value Structs

For simplicity, the web irb uses mrb\_load\_string to parse and execute ruby source together. Now here comes the problem, the function signature is like following:

{% highlight c %}
mrb_value
mrb_load_string(mrb_state *mrb, const char *s);
{% endhighlight %}

Here mrb\_value is a struct type. As a return value, it is passed by value here. This would forces emscripten to generate a JavaScript function like following:

{% highlight js %}
function _mrb_load_string($agg_result, $mrb, $s) {
  // code omitted...
}
{% endhighlight %}

The $agg\_result variable is used to "marked" a place in heap so as to store the return value, the consequence of which is that it is hard for us to make up a reasonable value in JavaScript. So we have to think of other ways.

Luckily, we do not need the return value here. Hence we can simply create a wrapper:

{% highlight c %}
int driver_execute_string(mrb_state *mrb, const char *s)
{
  mrb_load_string(mrb, s);

  return 0;
}
{% endhighlight %}

If at later times we decide to add logic to check the return value of mrb\_load\_string, we can simply added it here. For this driver function, the generated js function would only requires two arguments: the mrb state and the string to load.

##JavaScript code optimization

The generated JavaScript library is around 4.5M, it contains a lot of spaces and comments. Normally we do not want the browser to load "human-readable" JavaScript source code, an optimizer is in need here.

Emscripten has a built-in optimizer, but it wouldn't work with mruby:

{% highlight python %}
Stack: Error
    at assertTrue (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))
    at substrate.addActor.processItem.item.functions.forEach.Functions.blockAddresses.(anonymous function) (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))
    at Array.forEach (native)
    at substrate.addActor.processItem.item.functions.forEach.Functions.blockAddresses.(anonymous function) (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))
    at Array.forEach (native)
    at substrate.addActor.processItem (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))
    at Array.forEach (native)
    at Object.substrate.addActor.processItem (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))
    at Object.Actor.process (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))
    at Object.Substrate.solve (eval at globalEval (/Users/rafael/develop/webruby/modules/emscripten/src/compiler.js:103:8))

undefined:54
    throw msg;
          ^
Assertion failed: Only some can lead to labels with phis:_mrb_run,51,indirectbr
Traceback (most recent call last):
  File "/Users/rafael/develop/webruby/modules/emscripten/emscripten.py", line 402, in <module>
    temp_files.run_and_clean(lambda: main(keywords))
  File "/Users/rafael/develop/webruby/modules/emscripten/tools/shared.py", line 420, in run_and_clean
    func()
  File "/Users/rafael/develop/webruby/modules/emscripten/emscripten.py", line 402, in <lambda>
    temp_files.run_and_clean(lambda: main(keywords))
  File "/Users/rafael/develop/webruby/modules/emscripten/emscripten.py", line 358, in main
    emscript(args.infile, settings, args.outfile, libraries)
  File "/Users/rafael/develop/webruby/modules/emscripten/emscripten.py", line 228, in emscript
    for func_js, curr_forwarded_data in outputs:
ValueError: need more than 1 value to unpack
Traceback (most recent call last):
  File "/Users/rafael/develop/webruby/modules/emscripten/emcc", line 1092, in <module>
    final = shared.Building.emscripten(final, append_ext=False, extra_args=extra_args)
  File "/Users/rafael/develop/webruby/modules/emscripten/tools/shared.py", line 902, in emscripten
    assert os.path.exists(filename + '.o.js') and len(open(filename + '.o.js', 'r').read()) > 0, 'Emscripten failed to generate .js: ' + str(compiler_output)
AssertionError: Emscripten failed to generate .js: 
{% endhighlight %}

Oops, maybe I need to turn to [Alon](https://github.com/kripken/emscripten) for help here-\_-

But luckily, we still have [Closure Compiler](https://developers.google.com/closure/compiler/). It works on mruby source code. With simple optimizations we can strip the generated JavaScript source file to around 1.6M. This looks like a workable solution. Advance optimizations require we export the driver functions, otherwise all mruby related source code will be cut out since we never use them in this single file. Well, I'll come back to this later, 1.6M does not look that bad already~

##Conclusion

Now the mruby irb runs in a browser, and the mruby tests also [pass](/2012/11/22/make-mruby-tests-pass-in-a-browser) in either Node.js or a browser. The fun part can continue. I know I said in my previous [post](/2012/12/11/mruby-browser-is-now-called-webruby) that I will work on a OpenGL ES 2.0 API, well, the thing is I've got a nice idea on a mruby-to-JavaScript calling interface. If I can get this working, we will have the WebGL API, canvas API, Web Audio API, etc at hands instantly! Sounds nice, huh? And of course, it can and will be organized as a mrbgem, except that a small JavaScript part is needed to attached to the generated JS file via emscripten.

Anyway, I've already created the [repository](https://github.com/xxuejie/mruby-js) for this, let's see if I can make this work:)
