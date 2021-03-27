--[[
LZ77 compressor (by Assembler Bot)

Compression scheme:
	In compression stream is:
	
	values in stream:
		A -> 32..47            = color value 0..15
		B -> 48..64 or 94..255 = number in range 0..178
		C -> 32..64 or 94..255 = number in range 0..194
	
	blocks:
		A -> direct color output
		
		B -> 101..178 = coherence run: ofs=w, length=value-101+2

		B -> 0..100 = run: length=value+2
		C -> offset
			- special case if length == 127+2, follows C*C = length - 127-2 (for large empty areas)
	
	Block of colors of decoded length are copied from decompressed stream from position current-offset to current (self-overlapping is allowed and desired).
]]

max_run_len=100

function lz77_out_a(value) -- 0..15
	if value<0 or value>15 then
		stop("value A out of range! "..value)
	end
	
	return chr(value+32)
end

function lz77_out_b(value) -- 0..178
	if value<0 or value>178 then
		stop("value B out of range! "..value)
	end

	if value<17 then
		return chr(value+48)
	else
		return chr(value+94-17)
	end
end

function lz77_out_c(value) -- 0..194
	if value<0 or value>194 then
		stop("value C out of range! "..value)
	end
	
	if value<33 then
		return chr(value+32)
	else
		return chr(value+94-33)
	end
end


function lz77_comp(x0,y0,w,h,vget)
	local pixels={}
	for y=0,h-1 do
		for x=0,w-1 do
			add(pixels,vget(x,y))
		end
	end
	
	local out=""
	local i=1
	while i<=#pixels do
		local p=pixels[i]
		
		local run=0
		local ofs=0
		for j=max(1,i-195),i-1 do
			local k=0
			while i+k<=#pixels and pixels[i+k]==pixels[j+k] do k+=1 end
			if k>run or (k>=run-1 and i-j==w) then
				run=k
				ofs=i-j
			end
		end

		if run<2 or (run==2 and ofs~=w) then
			-- direct pixel output
			out=out..lz77_out_a(p)
			i+=1
		elseif ofs==w then
			-- row with coherence
			run=min(run,178-(max_run_len+1)+2)

			out=out..lz77_out_b(run-2+max_run_len+1)
			i+=run
		else
			-- run
			run=min(run,max_run_len+2)
			
			out=out..lz77_out_b(run-2)
			out=out..lz77_out_c(ofs-1)

			i+=run
		end
	end
	return out
end
