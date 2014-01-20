I always want a printf(). This provides it. The underlying formatting is
lua's string.format, with the limitations thereof.

What you get, all happily stashed in Library.printf.*:

    sprintf()	Returns a formatted string.
    printf()	Prints a string to the default console.
    cprintf()	Prints to the specified console

e.g.:
    cprintf('combat', "Message for combat log: %s.", some_string)

There are also suffixed variants for cprintf/printf:
    printfh()	Enable limited HTML (see the Rift docs)
    printfs()	Suppress leading addon identifier.
    printfhs()	Suppress leading addon identifier, enable limited HTML.
And, likewise, sprintfh() for HTML-aware behavior.

Finally, last but not least:
    console(console-id)
    	Change default console ID for the currently-running addon.

If a given addon has not called Library.printf.console(), the default will
be 'general'.

The HTML variants scan the argument list for strings, and replace <>
with &lt; and &gt; to prevent HTML formatting errors, but will not do this
to the format string itself. To avoid this, there is a function
html_safe(), which takes a string and yields a thing which can map to
a %s without being escaped. (It's a table with the string as the .s field
and a metatable with a __tostring() which returns that.)

The printf() calls should be robust in the face of invalid arguments and
suchlike.

