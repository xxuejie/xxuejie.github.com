---
layout: post
title: "mruby to JavaScript? Well, maybe this is not a working path as I thought"
date: 2012-12-25 21:12
comments: true
categories: mruby JavaScript
---
Merry Christmas everyone! Honestly Christmas is not so important for me but it may be very important for you guys:) Also wish everyone of you a Happy New Year!

I said in my last [post](/2012/12/18/mruby-irb-running-in-browser) that I had a nice idea on a calling interface from mruby to JavaScript. But after some time's investigation, I start to wonder if I was being too optimistic. Anyway, here's my original idea:

Ruby is a dynamic language, so is JavaScript. The only thing that caught us is the C layer in between(being a pathetic C99 lover, I just prefer to ignore C++). However, all we need to do here is to figure out what function we want to call as well as all the arguments(from Ruby side) and pass all them through the C layer to the JavaScript side. We do not need to do any execution in the C layer.

Here's the point: suppose we have a Ruby object, which represents the `document` object in DOM. We can use `method_missing` to capture the function we want to call and all the arguments, pass them through the C layer and invoke it in the JavaScript side. Now comes the tricky part: while the function is represented by a string(or a symbol in Ruby side), we cannot refer to the actual function in the C side, but neither do we need to do this. We can just pass the string over to the JavaScript side and use `method_missing.function_name` to get this function. Problem solved.

Did you see my mistake? What I miss here is that getting the function is only one side of the stories. We still have all the arguments to process. At mruby side we have `mrb_value` that tells us the type of the argument, but when passing through the C layer, we need to resolve to the `va_list` mechanism(similar, but it is not called this in emscripten) for passing variable numbers of arguments. How are we going to preserve the types here? How can we distinguish a string from a number in JavaScript?

I could build a `mrb_value`-like type to use in `va_list`-like structure when handling control to JavaScript, but struct passing seems difficult, if not impossible, to process in emscripten. What's more, This may bring more performance cost, while running mruby on top of JavaScript already makes execution slower than pure JavaScript.

Or maybe I can also pass in an array of strings to the JavaScript side specifying the types of each arguments. While this array could be generated automatically, the question is still there: does it worth the cost?

Maybe my original plan on an OpenGL ES 2.0 API is right-_- Anyway, I will update here if I have more results.

**Update**: Well, I manage to succeed in building an interface using neither of the methods above! I just pass the pointer(array) of values to the JS side, and then let the JS code call "back" to the C code to process the arguments one-by-one. The cost should not be more than simply looping through the arguments. The internal structure of mruby calling stack helps a lot in this implementation! If you are interested, feel free to check out the [code](https://github.com/xxuejie/mruby-js), specifically this [commit](https://github.com/xxuejie/mruby-js/commit/60016e969ed767540e3dad4dec7d2e1622c39c73).
