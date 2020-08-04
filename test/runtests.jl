using TypeProfiler

# global ref
# ----------

foo(a) = return bar(a)
@profile_call foo(nothing)

# boolean condition check
# -----------------------

foo(a) = a ? a : nothing
foo() = (c = rand(Any[1,2,3])) ? c #=c is Any typed=# : nothing

@profile_call foo(1) # report
@profile_call foo(true) # not report
@profile_call foo() # not report because it's untyped

# old
# ---

@profile_call sum("julia")
@profile_call sum([])

fib(n) = n <= 2 ? n : fib(n - 1) + fib(n - 2)
@profile_call fib(100) # never ends otherwise

fib′(n) = n <= 2 ? n : fib′′(n - 1) + fib′(n′ - 2)
@profile_call fib′(100) # never ends otherwise
