local Graph={}
function Graph.Path(samples,field,max,width,height,now,window)
 local out={}
 for _,p in ipairs(samples) do
  if p[field]~=nil and p.time<=now then
   local x=width*(1-(now-p.time)/window)
   local y=height*(1-math.min(max,math.max(0,p[field]))/max)
   if x>=0 then out[#out+1]=string.format('%s%.2f,%.2f',#out==0 and '' or ' | LineTo ',x,y) end
  end
 end
 if #out==0 then return '0,0 | LineTo 0,0' end
 if #out==1 then out[#out+1]=' | LineTo '..out[1] end
 return table.concat(out)
end
function Graph.Axis(samples,minimum)
 local axis=minimum or 1024
 for _,p in ipairs(samples) do while math.max(p.down or 0,p.up or 0)>axis do axis=axis*2 end end
 return axis
end
return Graph
