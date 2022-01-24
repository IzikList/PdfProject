var pdfjsLib = window['pdfjs-dist/build/pdf'];
pdfjsLib.GlobalWorkerOptions.workerSrc = '//mozilla.github.io/pdf.js/build/pdf.worker.js';
var cvsArray = [];
document.getElementById('in').onchange = function(ev) {
    var file = event.target.files[0];
    window.inputFile = file;
    var fileReader = new FileReader();  
  
    fileReader.onload = function() {
        var typedarray = new Uint8Array(this.result);
        const loadingTask = pdfjsLib.getDocument(typedarray);
        loadingTask.promise.then(pdf => {
            console.log('PDF loaded');
            window.pdf  = pdf;
            var pageNumber = 1;
            ocr();
        });           
    };
    fileReader.readAsArrayBuffer(file);
}
function getPages(index) {
    let csvss = document.getElementById('canvasHolder').children;
    csvss = Array.from(csvss).filter(a => a.selectedState);
    index = index || 0;
    pageNumber = parseInt(csvss[index].id.replace('pn', ''));

    div = document.getElementById('output');
    pdf = window.pdf;
    if(pageNumber > pdf.numPages){
      return;
    }
    div.innerHTML += '<h1>Page ' + pageNumber + '</h1>'
    pdf.getPage(pageNumber).then(function(page) {
        page.getTextContent().then(data => {
            console.log(data);
            for (var item of data.items) {
                console.log(item.str);
                div.innerHTML += item.str + '<br />';
            } 
            getPages(index + 1);
        });
    }) 
}

const { createWorker } = Tesseract;

function convert () {
    let csvss = document.getElementById('canvasHolder').children;
    csvss = Array.from(csvss).filter(a => a.selectedState);
    index = 0;
    pageNumber = parseInt(csvss[index].id.replace('pn', ''));

    logger = document.getElementById('status');
    let progressCbk = (data) => {logger.innerHTML = 'Page ' + pageNumber + ': ' + data.progress}
    let innerCalback = function(canvas) {
        innerConvert(canvas, function(text){
            alert(text);
            index++;
            if(index >= csvss.length) return;
            pageNumber = parseInt(csvss[index].id.replace('pn', ''));
            converOcr(pageNumber, 1.5, innerCalback, progressCbk)
        }, progressCbk)
    }
    converOcr(pageNumber, 1.5, innerCalback)
}
async function innerConvert(cvs, cbk, progress) {
    const worker = createWorker({
        workerPath: '../node_modules/tesseract.js/dist/worker.min.js',
        langPath: '../lang-data',
        corePath: '../node_modules/tesseract.js-core/tesseract-core.wasm.js',
        logger: m => {console.log(m); if(progress) progress(m)},
        });
          
    await worker.load();
    await worker.loadLanguage('eng');
    await worker.initialize('eng');
    // (array[ind - 1]);
    const { data: { text } } = await worker.recognize(cvs);
    await worker.terminate();
    if(cbk) cbk(text);
}
function ocr() {
    let pageNumber = 1;
    if(pageNumber > window.pdf.numPages) {
        return;
    }

    ocrCallback = function(canvas) {
        if(pageNumber > window.pdf.numPages) {
            return;
        }
        canvas.id = 'pn' + pageNumber;
        canvas.onclick = function() {this.selectedState =  this.selectedState?  false : true;
                            this.style.border = this.selectedState ? '1px black solid' : ''}
        document.getElementById('canvasHolder').appendChild(canvas);
        pageNumber++;
        converOcr(pageNumber, 0.5, ocrCallback);
    }
    converOcr(pageNumber, 0.5, ocrCallback);
}

function converOcr(pageNumber,scale, cbk){
    window.pdf.getPage(pageNumber).then(function(page) {
        var viewport = page.getViewport({scale: scale});
        
        var canvas = document.createElement('canvas');
        var context = canvas.getContext('2d');
        canvas.height = viewport.height;
        canvas.width = viewport.width;
    
        var renderContext = {
          canvasContext: context,
          viewport: viewport
        };
        var renderTask = page.render(renderContext);
        renderTask.promise.then(function () {
          console.log('Page rendered');
          cbk(canvas)
        });
    });
    

}
