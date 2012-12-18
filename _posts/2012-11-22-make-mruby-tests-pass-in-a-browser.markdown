---
layout: post
title: "Make mruby tests pass in a browser"
date: 2012-11-22 12:22
comments: true
categories: mruby JavaScript
sharing: false
---
With my Hadoop paper submitted last Friday, I can spend more time playing with mruby. Now after several days' hacking, I finally manage to make all mruby tests pass in a browser or in node.js.

{% highlight bash %}
$ make test
make[2]: Nothing to be done for `all'.
make[2]: Nothing to be done for `all'.
make[2]: Nothing to be done for `all'.
make[2]: Nothing to be done for `all'.
Running mruby test in Node.js!
node ./build/mruby-test.js
mrbtest - Embeddable Ruby Test

This is a very early version, please test and report errors.
Thanks :)

......................................................................................
......................................................................................
......................................................................................
......................................................................................
......................................................................................
.............................................................
Total: 491
   OK: 491
   KO: 0
Crash: 0
 Time: 1.999 seconds

{% endhighlight %}

Now it's time to keep a note on how to make these tests passed.

As this [Issue](https://github.com/kripken/emscripten/issues/705) is resolved(Thanks to Alon Zakai for his super fast commit to fix this!), the mruby source code can be compiled using `emcc` successfully, the sample `main.c` file also works. But there are still 5 tests left that are not passed: 2 of them failed, while the other 3 caused node.js to crash. These 5 tests are:

* Tests for `erf` and `erfc` functions in `math.rb`
* `Float#round [15.2.9.3.12]` in `float.rb`
* `String#to_f [15.2.10.5.39]` in `string.rb`
* `Exception 14` in `exception.rb`
* `Proc.new [15.2.17.3.1]` in `proc.rb`

To be honest, the result is quite good, since only 5 of the 489 tests got problems. I guess `emscripten` really has reached a pretty mature status thanks to Alon. Most of the fixes here are resolved from commits to `mruby` or `emscripten` directly. However, there are also annoying ones. Anyway, I will explain how to make each of them pass.

## `erf` and `erfc` functions

Honestly, this is the first time that I heard about these two functions. They reside in the `math.h` header file of standard C library. The `erf` function is used to calculate the error function of a value `x`. While the 'erfc' function calculates the complementary error function of `x`. `emscripten` does not come with an implementation for this function. However, there is an implementation in `math.c` of `mruby` for MSVC, which does not provide `erf/erfc` functions. It was originally take from [here](http://www.digitalmars.com/archives/cplusplus/3634.html):

{% highlight c %}
double
erf(double x)
{
  static const double two_sqrtpi =  1.128379167095512574;
  double sum  = x;
  double term = x;
  double xsqr = x*x;
  int j= 1;
  if (fabs(x) > 2.2) {
    return 1.0 - erfc(x);
  }
  do {
    term *= xsqr/j;
    sum  -= term/(2*j+1);
    ++j;
    term *= xsqr/j;
    sum  += term/(2*j+1);
    ++j;
  } while (fabs(term/sum) > MATH_TOLERANCE);
  return two_sqrtpi*sum;
}
{% endhighlight %}

What's worth noting is that the original `mruby` implementation contains a bug which will give wrong results for negative values. The original post from digitalmars also has a fix for this problem. It was just the case that the original commiter uses the earlier version without the fix. Hence a simple [commit](https://github.com/mruby/mruby/commit/f7dd27a92827af91aa52c78bfbf96d5f7e73c4bd) to the `mruby` project solved this problem. A similar [version](https://github.com/kripken/emscripten/commit/9be35831f0741070e495622e6c7ba51fbbb6475c) in JavaScript could also be implemented, the `erf/erfc` test would then pass.

## `Fload#round` test

This is an interesting and easy one. The test code resides at [here](https://github.com/mruby/mruby/blob/master/test/t/float.rb#L96). Actually all the round tests give the correct result, what went the wrong is that `==` is used to test equality for two floating point values. A small [commit](https://github.com/mruby/mruby/commit/a9c8ae49ebe1c54b93dcffa46370d4099e0c7ea3) fixes this, easy one.

## `String#to_f` test

This is also related floating point value. The code is at [here](https://github.com/mruby/mruby/blob/master/test/t/string.rb#L325). `b` should be assigned to `123456789.0`, when using `check_float` to compare `b` with `123456789.0`, they should be treated as equality. Funny thing is that node.js would give the result of `1.4901161193848e-08` as the difference between the two values, while `check_float` would only consider two values to be the same if they are within `1E-12`.

Simply changing Line #328 to `123456789` instead of `123456789.0` would give the correct result, but this is a very bad fix for this problem and does not really solve it. Basically there may be two reasons:

1. Somewhere in the generated JavaScript code of `emscripten`, the code does not treat the floating point value well.
2. `v8` does not provide that many precisions for floating point value.

It is still unknown which is the cause for this problem. What I choose to do now is to let `mruby` use float instead of double. When using float, `check_float` would accept two values within `1E-5`, for which the current result of `1.4901161193848e-08` will be enough. Anyway, I will come back to this later, maybe a dig into the `v8` issue list can bring some insight into this.

## `Exception 14` and `Proc.new [15.2.17.3.1]`

Both the [exception](https://github.com/mruby/mruby/blob/master/test/t/exception.rb#L261) and [proc](https://github.com/mruby/mruby/blob/master/test/t/proc.rb#L12) tests crash `node.js`, and they both use a `begin ... rescue ... end` statement with a method call in the `begin` clause. A simple guess is that they are due to the same reason.

I spent a whole day debugging this problem by inserting debug statements in mruby source code, reading generated logs as well as JavaScript source code written in assembly style. The `LABEL_DEBUG` option in `emscripten` proves to be a huge help here(thanks again, Alon!). Finally the problem turns out to be the need for stack manipulation setjmp/longjmp. I prepared a [gist](https://gist.github.com/4128331) describing this problem:

{% highlight c %}
#include <setjmp.h>
#include <stdio.h>

typedef struct {
  jmp_buf* jmp;
} jmp_state;

void stack_manipulate_func(jmp_state* s, int level) {
  jmp_buf buf;

  printf("Entering stack_manipulate_func, level: %d\n", level);

  if (level == 0) {
    s->jmp = &buf;
    if (setjmp(*(s->jmp)) == 0) {
      printf("Setjmp normal execution path, level: %d\n", level);
      stack_manipulate_func(s, level + 1);
    } else {
      printf("Setjmp error execution path, level: %d\n", level);
    }
  } else {
    printf("Perform longjmp at level %d\n", level);
    longjmp(*(s->jmp), 1);
  }

  printf("Exiting stack_manipulate_func, level: %d\n", level);
}

int main(int argc, char *argv[]) {
  jmp_state s;
  s.jmp = NULL;

  stack_manipulate_func(&s, 0);

  return 0;
}
{% endhighlight %}

The original gist also comes with logs running this natively or via `emscripten`. With a stack manipulating setjmp/longjmp, the longjmp would erase the stack for level 1 calling of `stack_manipulate_func`. The program would only call the exiting printf once. However, with the current implementation of setjmp/longjmp in `emscripten`, the stack is not changed, the exiting printf will be call by both the level 0 and level 1 version of `stack_manipulate_func`.

I don't think it is very likely that we will have a stack manipulation setjmp/longjmp in JavaScript. So the use of setjmp/longjmp needs to be removed from `mruby`. But wait, does this sound similar? Didn't I just come up with a solution a few days earlier? Well, it is just in my first [post](http://qiezi.me/blog/2012/11/07/running-mruby-in-a-browser/) on `mruby`. I created a [patch](https://github.com/xxuejie/mruby-browser/blob/19365625b1a2e215af69e8196053a17a33bebfed/patches/01-mruby-use-exception.patch) to use C++ exception instead of setjmp/longjmp and then found out that our simple `main.c` file does not need this to run. Well, now we do. So I have to bring [it](https://github.com/xxuejie/mruby-browser/blob/4a8e43d6ab9fd4c0d86e140f9db316b342c891df/patches/01-use-cpp-exception.patch) back. This is really bad news for a pathetic C99 lover to find that the dependency for a C++ compiler returns-\_-

Quick Update: Actually Alon [confirms](https://groups.google.com/forum/?fromgroups=#!topic/emscripten-discuss/Xbu48Tvd2mk) that this is just a bug and it is fixed. So maybe we can still have a C99 solution on this problem. Interesting, I will take a look at this later. I really feel sick about using a C++ compiler, that may bring a lot of evil stuff when working on the later parts involving more C code, such as C function calling interface.

Anyway, now all the tests have passed. Not only in node.js but also in browsers. However, the time to run tests differ greatly:

* Chrome 23: 1.682s
* Firefox Aurora 18: 5.294s
* Safari 6: 0.394s

This is interesting. Safari is so fast that one can think something went wrong for the other two.

At this time, I believe the testing for mruby in JavaScript has finished. I will spend some time trying to create a irb for the browser and see if I can get it on repl.it. After that I can finally spend the time on C function calling. I wish it could be more fun than debugging the generated JavaScript code-\_-
