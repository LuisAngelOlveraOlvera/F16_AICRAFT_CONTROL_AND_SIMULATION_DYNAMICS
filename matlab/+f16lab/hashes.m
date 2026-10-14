function out=hashes
root=fileparts(fileparts(mfilename('fullpath')));files=[dir(fullfile(root,'*.m'));dir(fullfile(root,'+f16lab','*.m'))];
out=struct('archivo',{},'sha256',{});
for k=1:numel(files)
    path=fullfile(files(k).folder,files(k).name);f=fopen(path,'rb');assert(f~=-1);bytes=fread(f,Inf,'*uint8');fclose(f);
    md=java.security.MessageDigest.getInstance('SHA-256');md.update(bytes);hash=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
    out(k)=struct('archivo',strrep(path,[root filesep],''),'sha256',hash); %#ok<AGROW>
end
end
