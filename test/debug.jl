using JET, InteractiveUtils
using JET: typeof′, profile_call, print_reports
using Base.Meta: isexpr

versioninfo(stdout)

macro benchmark(ex, kwargs...)
    @assert isexpr(ex, :call) "function call expression should be given"
    f = first(ex.args)
    args = ex.args[2:end]

    return quote let
        println(stdout)
        argtypes = $(typeof′).(($(map(esc, args)...),))
        @info "profiling for $($(QuoteNode(ex))) ..."
        @time interp, frame = $(profile_call)($(esc(f)), argtypes; $(map(esc, kwargs)...))
        @info "$(length(interp.reports)) errors reported for $($(QuoteNode(ex)))"
        interp, frame
    end end
end

@eval Base begin
    function list_deletefirst!(q::InvasiveLinkedList{T}, val::T) where T
        val.queue === q || return
        head = q.head::T
        if head === val
            if q.tail::T === val
                q.head = q.tail = nothing
            else
                q.head = val.next::T
            end
        else
            head_next = head.next
            while head_next !== val
                head = head_next
                head_next = head.next::Union{T, Nothing}
            end
            head = head::T # assume `val` is found
            if q.tail::T === val
                head.next = nothing
                q.tail = head
            else
                head.next = val.next::T
            end
        end
        val.next = nothing
        val.queue = nothing
        return q
    end
end

interp, frame = @benchmark rand(Bool)
print_reports(stdout, interp.reports; annotate_types = true)
