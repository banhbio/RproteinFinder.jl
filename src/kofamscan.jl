struct Kofamscan
    cpu::Int
    input::String
    tmpdir::String
    profiledir::String
    ko_list::String
    result::Kofamout
end

function Kofamscan(input::String, outdir::String, tmpdir::String, profiledir::String, ko_list::String, cpu::Int)
    namae = basename(input)
    kofamout_path = joinpath(outdir, namae * ".kofam.tblout")
    kofamout = Kofamout(kofamout_path, input, profiledir, ko_list)
    return Kofamscan(cpu, input, tmpdir, profiledir, ko_list, kofamout)
end

function run(kofamscan::Kofamscan)
    tabdir = joinpath(kofamscan.tmpdir, "tabular")
    mkpath(tabdir)
    profile_list = parse_ko_list(kofamscan.ko_list, kofamscan.profiledir)
    tblouts = run_hmmsearch(kofamscan.input, tabdir, profile_list, kofamscan.cpu)
    make_kofamout(kofamscan.result, tblouts)
end

function run_hmmsearch(input::String, outdir::String, profile_list::Vector{Profile}, cpu::Int) 
    tblouts = Tblout[]
    for profile in profile_list
        namae = basename(path(profile))
        output = joinpath(outdir, namae)
        hmmsearch = Hmmsearch(input, profile, output, 1e-05, cpu)
        run(hmmsearch)
        tblout = result(hmmsearch)
        push!(tblouts, tblout)
    end
    return tblouts
end

function parse_ko_list(ko_list::String, profile_dir::String)
    profile_list = Profile[]
    open(ko_list,"r") do f
        readline(f)
        for l in eachline(r)
            row = split(l, "r`\t")
            knum = row[1] 
            threshold = row[2]
            type = row[3]

            path = joinpath(profile_dir, knum)
            profile = Profile(path, type, threshold)
            push!(profile_list, profile)
        end
    end
    return profile_list
end

function make_kofamout(kofamout::Kofamout, tblouts::Vector{Tblout})
    open(path(kofamout), "w") do o
        for tblout in tblouts
            for hit in hits(tblout)
                write(o, join(hit, "\t", "\n"))
            end
        end
    end
end

result(kofamscan::Kofamscan) = kofamscan.result