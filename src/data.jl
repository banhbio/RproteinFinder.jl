abstract type AbstractData end

@inline path(d::AbstractData) = d.path

struct Blastout <: AbstractData
    path::String
    query::String
    subject::String
end

@inline query(blastout::Blastout) = blastout.query
@inline subject(blastout::Blastout) = blastout.subject

struct Profile <: AbstractData
    path::String
    type::String
    threshold::Float64
end

struct Kofamout <: AbstractData
    path::String
    query::String
    profiledir::String
    ko_list::String
end

struct KofamResult
    id::String
    ko::String
    score::Float64
    threshold::Float64
    evalue::Float64
end

id(kofamresult::KofamResult) = kofamresult.id
join(kofamresult::KofamResult, delim::AbstractString) = join([kofamresult.id, kofamresult.ko, kofamresult.score, kofamresult.threshold, kofamresult.evalue], delim)

function hits(kofamout::Kofamout)
    result = KofamResult[]
    open(path(kofamout), "r") do f
        for l in eachline(f)
            row = split(l, "\t")
            @assert row == 5
            kofamresult = KofamResult(row[1],row[2],row[3],row[4],row[5])
            push!(result, kofamresult)
        end
    end
    return result
end

struct Tblout <: AbstractData
    path::String
    query::String
    profile::Profile
end

function kofamhits(tblout::Tblout)
    hit_list = KofamResult[]
    profile = tblout.profile
    if profile.type == "full"
        score_row = 6
    else
        score_row = 9
    end

    open(path(tblout), "r") do f
        for l in eachline(f)
            l[1] == '#' ? continue : nothing
            rows = split(l, r" +")
            id = rows[1]
            ko = rows[3]
            score = parse(Float64, rows[score_row])
            evalue = parse(Float64, rows[score_row-1])
            if score >= profile.threshold
                hit = KofamResult(id, ko, score, profile.threshold, evalue)
                push!(hit_list, hit)
            end
        end
    end

    return hit_list
end

function besthit(tblout::Tblout)
    open(path(tblout), "r") do f
        result = BlastResult[]
        
        tmp_besthit = nothing
        bestscore = 0
        id = nothing
        for l in eachline(f)
            record = BlastResult(l)
            new_score = record.birscore
            new_id = record.qseqid
            if id == new_id
                if new_score > bestscore
                    tmp_besthit = record
                end
            else
                push!(result, tmp_besthit)
                tmp_besthit = nothing
                bestscore = 0
                id = nothing
            end
        end
        return result
    end            
end