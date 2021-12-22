abstract type AbstractExternalProgram end

run(ep::AbstractExternalProgram) = run(ep.cmd)
result(ep::AbstractExternalProgram) = run(ep.result)

struct Musle <: AbstractExternalProgram
    cmd::Cmd
    cpu::Int
    input::String
    result::MSA
end

function Musle(input::String, result::MSA, cpu::Int)
    cmd = `musle -align $(input) -output $(result) -threads $(cpu) -amino`
    return Musle(cmd, cpu, input, result)
end

struct Hmmbuild<: AbstractExternalProgram
    cmd::Cmd
    cpu::Int
    input::MSA
    result::Profile
end

function Hmmbuild(input::MSA, result::Profile, cpu::Int)
    cmd = `hmmbuild --amino --cpu $(cpu) $(result) $(input)`
    return Hmmbuild(cmd, cpu, input, result)
end

struct Hmmsearch <: AbstractExternalProgram
    cmd::Cmd
    cpu::Int
    input::Profile
    result::Tblout
end

function Hmmsearch(input::String, profile::Profile, result::Tblout, cpu::Int)
    min = minbit(profile)
    cmd = `hmmsearch --tblout $(result) -T $(min) --cpu $(cpu) $(profile) $(input)`
    return Hmmsearch(cmd, cpu, input, result)
end
