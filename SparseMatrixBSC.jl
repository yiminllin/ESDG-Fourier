# Code originally by Kristoffer Carlsson (2016-ish)
# Code modified by Jesse Chan (2020)
struct SparseMatrixBSC{Tv, Ti <: Integer}
    R::Int                 # Block size in rows
    C::Int                 # Block size in columns
    m::Int                 # Number of rows
    n::Int                 # Number of columns
    colptr::Vector{Ti}     # Column i is in colptr[i]:(colptr[i+1]-1)
    rowval::Vector{Ti}     # Row values of blocks
    nzval::Array{Tv, 3}    # Nonzero values, one "matrix" per block, nzval[i, j, block]

    function SparseMatrixBSC(R::Integer, C::Integer,
                             m::Integer, n::Integer,
                             colptr::Vector{Ti}, rowval::Vector{Ti},  nzval::Array{Tv, 3}) where {Ti, Tv}
      m < 0 && throw(ArgumentError("number of rows (m) must be ≥ 0, got $m"))
      n < 0 && throw(ArgumentError("number of columns (n) must be ≥ 0, got $n"))

      R < 0 && throw(ArgumentError("block size y must be ≥ 0, got $x_block_size"))
      C < 0 && throw(ArgumentError("block size x must be ≥ 0, got $y_block_size"))

      m % R != 0 && throw(ArgumentError("row block size: $(R) must evenly divide number of rows: $m"))
      n % C != 0 && throw(ArgumentError("column block size: $(C) must evenly divide number of rows: $n"))
      new{Tv, Ti}(Int(R), Int(C), Int(m), Int(n), colptr, rowval, nzval)
  end
end

function SparseMatrixBSC(m::Integer, n::Integer, colptr::Vector{Ti}, rowval::Vector{Ti}, nzval::Array{Tv, 3}) where {Tv, Ti<:Integer}
    R, C = size(nzval, 1), size(nzval, 2)
    SparseMatrixBSC(R, C, m, n, colptr, rowval, nzval)
end

###########################
# Conversions CSC <-> BSC #
###########################

nblocks(A::SparseMatrixBSC) = (length(A.colptr) - 1, A.n ÷ A.C)
nblocks(A::SparseMatrixBSC, i::Int) = nblocks(A)[i]
blocksize(A::SparseMatrixBSC) = A.R, A.C
blocksize(A::SparseMatrixBSC, i::Int) = blocksize(A)[i]

# Column i is in colptr[i]:(colptr[i+1]-1)
nzblockrange(A::SparseMatrixBSC, col::Integer) =  Int(A.colptr[col]):Int(A.colptr[col + 1] - 1) # returns range for blocks in column "col"

Base.size(A::SparseMatrixBSC) = (A.m, A.n)
Base.size(A::SparseMatrixBSC, i) = size(A)[i]
Base.eltype(A::SparseMatrixBSC) = eltype(A.nzval)
SparseArrays.nnz(A::SparseMatrixBSC) = length(A.nzval)

function SparseArrays.SparseMatrixCSC(A::SparseMatrixBSC{Tv, Ti}) where {Tv, Ti <: Integer}
    if blocksize(A) == (1,1)
        return SparseMatrixCSC(A.m, A.n, A.colptr, A.rowval, vec(A.nzval))
    end
    rowval = zeros(Ti, nnz(A))
    colptr = zeros(Ti, size(A, 2) + 1)
    nzval = zeros(Tv, length(A.nzval))

    count_row = 1
    count_col = 2
    colptr[1] = 1
    @inbounds for col in 1:nblocks(A, 2)
        blockrange = nzblockrange(A, col)
        n_blocks_col = length(blockrange)
        nnz_values_col = n_blocks_col * blocksize(A, 1)
        for j_blk in 1:blocksize(A, 2)
            # The new colptr is the previous one plus the number of nonzero elements in this column.
            colptr[count_col] = colptr[count_col - 1] + nnz_values_col
            count_col += 1
            for block in blockrange
                i_offset = (A.rowval[block] - 1) * blocksize(A, 1)
                for i_blk in 1:blocksize(A, 1)
                    nzval[count_row] = A.nzval[i_blk, j_blk, block]
                    rowval[count_row] = i_blk + i_offset
                    count_row += 1
                end
            end
        end
    end
    return SparseMatrixCSC(A.m, A.n, colptr, rowval, nzval)
end

function SparseMatrixBSC(A::SparseMatrixCSC{Tv, Ti}, R::Integer, C::Integer) where {Tv, Ti}
    if (R, C) == (1,1)
        return SparseMatrixBSC(1, 1, A.m, A.n, A.colptr, A.rowval, reshape(A.nzval, length(A.nzval), 1, 1))
    end

    A.m % R != 0 && throw(ArgumentError("row block size: $(R) must evenly divide number of rows: $(A.m)"))
    A.n % C != 0 && throw(ArgumentError("column block size: $(C) must evenly divide number of rows: $(A.n)"))

    Anzval = A.nzval
    Arowval = A.rowval
    Acolptr = A.colptr

    # Upper bound of number of nonzero blocks is nnz(A).
    rowval = zeros(Ti, nnz(A))
    colptr = zeros(Ti, A.n ÷ C + 1)

    n_colblocks = div(A.n, C)

    colptr[1] = 1
    row_counter = 1
    rows = Int[]

    # Strategy to compute rowval and colptr:
    # For each column block accumulate all the rowvalues in the CSC matrix for that block.
    # Convert these to what rowblock they represent
    # Each unique rowblock should now be entered in order into rowval.
    # Colptr for this column block is incremented by the number of unique rowblock values.
    @inbounds for colblock in 1:n_colblocks
        j_offset = (colblock - 1) * C
        row_block_counter = 1

        # Count the number of non zero values for the columns in this column block
        nzvals_block = Acolptr[j_offset + C + 1] - Acolptr[j_offset + 1]
        if nzvals_block == 0 # No nz values in this column block, exit early
            colptr[colblock + 1] = row_counter
            continue
        end

        # Accumulate rowvals for this block
        resize!(rows, nzvals_block)
        for j_blk in 1:C
            col = j_offset + j_blk
            nz_range = Acolptr[col]:Acolptr[col + 1] - 1
            for r in nz_range
                rows[row_block_counter] = Arowval[r]
                row_block_counter += 1
            end
        end

        # Convert from row values -> block rows
        @simd for i in 1:length(rows)
            rows[i] = (rows[i] - 1) ÷ R + 1
        end

        # Pick out the unique block rows and put them into rowval

        #######################
        sort!(rows) # <- A bit of a bottle enck, takes about 30% of tot time.
        #######################
        rowval[row_counter] = rows[1] # We have at least one value in rows so this is ok
        row_counter += 1
        for i in 2:length(rows)
            if rows[i] > rows[i-1]
                rowval[row_counter] = rows[i]
                row_counter += 1
            end
        end
        colptr[colblock + 1] = row_counter
    end

    # We now know the true number of non zero blocks so we reshape rowval
    # and allocate the exact space we need for nzval
    deleteat!(rowval, row_counter:length(rowval))
    nzval = zeros(Tv, R, C, length(rowval))

    @inbounds for colblock in 1:n_colblocks
        j_offset = (colblock - 1) * C
        for j_blk in 1:C
            current_block = colptr[colblock]
            col = j_offset + j_blk
            for r in Acolptr[col]:Acolptr[col + 1] - 1
                row = Arowval[r]
                # Looking for the correct block for this column
                while row > rowval[current_block] * R
                    current_block += 1
                end
                i_blk = row - (rowval[current_block] - 1) * R
                nzval[i_blk, j_blk, current_block] = Anzval[r]
            end
        end
    end

    SparseMatrixBSC(A.m, A.n, colptr, rowval, nzval)
end

# for fast CSC conversion: convert to SparseMatrixCSC nzval ordering
function getCSCordering(A::SparseMatrixBSC)

    # loop through all active columns
    R,C = blocksize(A)
    ntotalblocks = size(A.nzval,3)
    flattened_indices = reshape(1:R*C*ntotalblocks,R,C,ntotalblocks) # UnitRange avoids allocation
    CSC_permuted_indices = zeros(Int,R,C*ntotalblocks) # [col1, col2, ..., col_blocksize*nblocks]

    sk = 1
    for i = 1:length(A.colptr)-1
        # find i,j indices of each block in a col
        blocks_in_column = nzblockrange(A,i)
        for col = 1:C
            for block_id in blocks_in_column
                CSC_permuted_indices[:,sk] .= flattened_indices[:,col,block_id]
                sk += 1
            end
        end
    end

    return CSC_permuted_indices[:]
end

# fast conversion from BSC to CSC matrix
function SparseMatrixCSC!(B::SparseMatrixCSC,A::SparseMatrixBSC{Tv, Ti}, CSCpermuted_indices) where {Tv, Ti <: Integer}
    B.nzval .= A.nzval[:][CSCpermuted_indices] # need to add permutation, but this should be super fast
end

############
# Base interfaces #
############

function Base.show(io::IO, A::SparseMatrixBSC;
                   header::Bool=true, repr=false)
    print(io, A.m, "×", A.n, " sparse block matrix with ", size(A.nzval,3), " ",
        eltype(A), " blocks of size ", blocksize(A, 1),"×",blocksize(A, 2))
end

# convert from block index to CSC index
function getCSCindex(A::SparseMatrixBSC{Tv,Ti}, index::Block{2,Ti}) where {Tv,Ti}
    row,col  = index.n
    colrange = nzblockrange(A,col)
    rows     = A.rowval[colrange]
    index    = findfirst(rows.==row)
    if isnothing(index)
        return nothing
    else
        return colrange[index]
    end
end

function Base.getindex(A::SparseMatrixBSC{Tv,Ti}, blockindex::Block{2,Ti}) where {Tv,Ti}
    CSC_id = getCSCindex(A,blockindex)
    if isnothing(CSC_id)
        return zeros(blocksize(A)...)
    else
        return A.nzval[:,:,CSC_id]
    end
end

function Base.setindex!(A::SparseMatrixBSC{Tv,Ti}, val::Array{Tv,2}, blockindex::Block{2,Ti}) where {Tv,Ti}
    CSC_id = getCSCindex(A,blockindex)
    if isnothing(CSC_id)
        error("block index not in original sparsity pattern. adding new sparse blocks not currently supported")
    end
    if size(val)!=blocksize(A)
        error("assigned block is size ", size(val), ", block size is ", blocksize(A))
    end
    A.nzval[:,:,CSC_id] .= val
end



# ##########
# # LinAlg #
# ##########
#
# # We do dynamic dispatch here so that the size of the blocks are known at compile time
# function LinearAlgebra.mul!(b::Vector{Tv}, A::SparseMatrixBSC{Tv}, x::Vector{Tv}) where {Tv}
#     if blocksize(A) == (1,1)
#         mul!(b, SparseMatrixCSC(A), x)
#     else
#         _mul!(b, A, x, Val(A.C), Val(A.R))
#     end
# end
#
# function _mul!(b::Vector{Tv}, A::SparseMatrixBSC{Tv}, x::Vector{Tv},
#                              ::Val{C}, ::Val{R}) where {Tv, C, R}
#     fill!(b, 0.0)
#     n_cb, n_rb = nblocks(A)
#     for J in 1:n_cb
#         j_offset = (J - 1)  * blocksize(A, 2)
#         for r in nzblockrange(A, J)
#             @inbounds i_offset = (A.rowval[r] - 1) * blocksize(A, 1)
#             matvec_kernel!(b, A, x, r, i_offset, j_offset, Val(C), Val(R))
#         end
#     end
#     return b
# end
#
# # TODO: Possibly SIMD.jl and do a bunch of simd magic coolness for small mat * vec
# @inline function matvec_kernel!(b::Vector{T}, A::SparseMatrixBSC{T}, x::Vector{T}, r,
#                                 i_offset, j_offset, ::Val{C}, ::Val{R}) where {C, R, T}
#     @inbounds for j in 1:C
#         for i in 1:R
#             b[i_offset + i] += A.nzval[i, j, r] * x[j_offset + j]
#         end
#     end
# end
#
# function Base.:*(A::SparseMatrixBSC{Tv}, x::Vector{Tv}) where {Tv}
#     mul!(similar(x, A.m), A, x)
# end
