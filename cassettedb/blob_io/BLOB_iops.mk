
BLOB_iops.dll: dlldata.obj BLOB_io_p.obj BLOB_io_i.obj
	link /dll /out:BLOB_iops.dll /def:BLOB_iops.def /entry:DllMain dlldata.obj BLOB_io_p.obj BLOB_io_i.obj \
		kernel32.lib rpcndr.lib rpcns4.lib rpcrt4.lib oleaut32.lib uuid.lib \

.c.obj:
	cl /c /Ox /DWIN32 /D_WIN32_WINNT=0x0400 /DREGISTER_PROXY_DLL \
		$<

clean:
	@del BLOB_iops.dll
	@del BLOB_iops.lib
	@del BLOB_iops.exp
	@del dlldata.obj
	@del BLOB_io_p.obj
	@del BLOB_io_i.obj
