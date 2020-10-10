# code cache interface
# --------------------

CC.code_cache(interp::TPInterpreter) = TPCache(interp, code_cache(interp.native))

struct TPCache{NativeCache}
    interp::TPInterpreter
    native::NativeCache
    TPCache(interp::TPInterpreter, native::NativeCache) where {NativeCache} =
        new{NativeCache}(interp, native)
end
CC.WorldView(tpc::TPCache, wr::WorldRange) = TPCache(tpc.interp, WorldView(tpc.native, wr))
CC.WorldView(tpc::TPCache, args...) = WorldView(tpc, WorldRange(args...))

CC.haskey(tpc::TPCache, mi::MethodInstance) = CC.haskey(tpc.native, mi)

function CC.get(tpc::TPCache, mi::MethodInstance, default)
    # # for self profiling
    # if isa(mi.def, Method)
    #     # ignore cache for TypeProfiler's code itself
    #     mod = mi.def.module
    #     if mod == (@__MODULE__) || mod == JuliaInterpreter
    #         return default
    #     end
    #
    #     file = mi.def.file
    #     # ignoring entire cache for `Core.Compiler` will slows down profiling performance too bad
    #     if file === Symbol("compiler/typeinfer.jl") || file === Symbol("compiler/abstractinterpretation.jl")
    #         return default
    #     end
    # end

    ret = CC.get(tpc.native, mi, default)

    ret === default && return default

    # cache hit, now we need to invalidate the cache lookup if this `mi` has been profiled
    # as erroneous; otherwise the error reports that can occur from this frame will just be
    # ignored
    force_inference = false
    if haskey(ERRORNEOUS_LINFOS, mi)
        # don't force re-inference for frames from the same inference process;
        # FIXME: this is critical for profiling performance, but seems to lead to lots of false positives ...
        if ERRORNEOUS_LINFOS[mi] !== get_id(tpc.interp)
            force_inference = true
        end
    end

    return force_inference ? default : ret
end

CC.getindex(tpc::TPCache, mi::MethodInstance) = CC.getindex(tpc.native, mi)

CC.setindex!(tpc::TPCache, ci::CodeInstance, mi::MethodInstance) = CC.setindex!(tpc.native, ci, mi)
