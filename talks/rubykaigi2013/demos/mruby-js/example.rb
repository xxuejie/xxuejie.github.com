# gets window object
window = MrubyJs.window

# gets jQuery selected object, this is a function call!
# you can also use jQuery.invoke("#container")
container = window.jQuery["#container"]

# appends new tag
# another way of writing this: container.append["content"]
container.append("<p>This is inserted using run_source()!</p>")
