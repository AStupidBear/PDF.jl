module PDF

using PyCall

pyopen(fn, mode = "r") = pyimport("builtins")["open"](fn, mode)
function pyopen(f::Function, fn, mode = "r")
  s = pyopen(fn, mode)
  try f(s)
  finally pyclose(s)
  end
end
pywrite(s::PyObject, x) = x["write"](s)
pyclose(s::PyObject) = s["close"]()

PdfFileReader = pyimport("PyPDF2")["PdfFileReader"]
PdfFileWriter = pyimport("PyPDF2")["PdfFileWriter"]

numpages(s::PyObject) = s[:numPages]
getpage(s::PyObject, n::Int) = pycall(s["getPage"], PyObject, n - 1)
addpage!(s::PyObject, page::PyObject) = s["addPage"](page)
addbookmark!(s::PyObject, name::String, n::Int) = s["addBookmark"](name, n - 1)

export mergepdf
function mergepdf(fns = readdir(pwd()), fn_out = tempname() * ".pdf")
  fns = filter(x -> contains(x, ".pdf"), fns)

  pdfs = [PdfFileReader(pyopen(fn, "rb")) for fn in fns]
  pdf_out = PdfFileWriter()

  nb = 1
  for (fn, pdf) in zip(fns, pdfs)
    for n in 1:numpages(pdf)
      addpage!(pdf_out, getpage(pdf, n))
      n == 1 && addbookmark!(pdf_out, splitext(basename(fn))[1], nb)
      nb += 1
    end
  end

  pyopen(fn_out, "wb") do s
    pywrite(s, pdf_out)
  end
  fn_out
end

end
