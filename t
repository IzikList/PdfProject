var pdfjsLib = window['pdfjs-dist/build/pdf'];
pdfjsLib.GlobalWorkerOptions.workerSrc = '//mozilla.github.io/pdf.js/build/pdf.worker.js';

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
            var div = document.getElementById('output');
            document.getElementById('ocrHolder').style.visibility = 'visible'
            document.getElementById('in').style.display = 'none';
            getPage(pdf, pageNumber, div);
        });           
    };
    fileReader.readAsArrayBuffer(file);
}
function getPage(pdf, pageNumber, div) {
    if(pageNumber > pdf.numPages){
      return;
    }
    div.innerHTML += '<h1>Page ' + pageNumber + '</h1>'
    pdf.getPage(pageNumber).then(function(page) {
        page.getTextContent().then(data => {
            console.log(data);
            let index = 0;
            for (var item of data.items) {
                console.log(item.str);
                div.innerHTML += item.str + '<br />';
                index ++;
                if(index > 200){
                    break;
                }
            } 
            pageNumber++;
        });
    }) 
}

const { createWorker } = Tesseract;

function convert () {
    let csvss = document.getElementById('canvasHolder').children;
    csvss = Array.from(csvss).filter(a => a.selectedState);
    // let holders = csvss;
    // csvss = csvss.map(a => a.children[0]);
    innerConvert(csvss[0]);
    
    return;
    let index = 0;
    let outDiv = document.getElementById('output');
    outDiv.innerHTML = '';
    let pageNumber = parseInt(holders[index].id);

    ocrCallback = function(cvs) {
        document.body.appendChild(cvs);
        setTimeout(function() {
            innerConvert(cvs, function() {
                div.innerHTML += '<h1>Page' + (index + 1) + '</h1>' + text;
                index ++;
                if(index < csvss.length) {
                    let pageNumber = parseInt(holders[index].id);
                    converOcr(pageNumber, ocrCallback);
                }
            })
    
        }, 3000)

    }
    converOcr(pageNumber, ocrCallback)

}
async function innerConvert(cvs) {
    const worker = createWorker({
        workerPath: '../node_modules/tesseract.js/dist/worker.min.js',
        langPath: '../lang-data',
        corePath: '../node_modules/tesseract.js-core/tesseract-core.wasm.js',
        logger: m => console.log(m),
    });
          
    await worker.load();
    await worker.loadLanguage('eng');
    await worker.initialize('eng');
    const { data: { text } } = await worker.recognize(cvs); // ('../images/Fleszar, Leonard - LSI LE Cert 1-10-2022 (Ashar Group LLC).jpg');
    if(cbk) cbk(text)
    await worker.terminate();
}
function ocr() {
    converOcr(2)
}

function converOcr(pageNumber, cbk){
    if(pageNumber > window.pdf.numPages) {
        if(pageNumber > 1) {
            document.getElementById('convertHolder').style.display = 'block'
            document.getElementById('ocrHolder').style.display = 'none'
        }
        return;
    }
    window.pdf.getPage(pageNumber).then(function(page) {
        var scale = 1.5;// cbk? 1.5 : 0.75;
        var viewport = page.getViewport({scale: scale});
        
        var canvas = document.createElement('canvas');
        // canvas.onload = () => {alert('Cavnvas Looded ' + canvas.getContext('2d'))}
        // if(! cbk) {
        //     let canvasContainer = document.createElement('div');
        //     canvasContainer.id = '' + pageNumber;
            canvas.onclick = function() {this.selectedState =  this.selectedState?  false : true;
                                this.style.border = this.selectedState ? '1px black solid' : ''}
        //     canvasContainer.classList.add('canvasContainer');
        //     canvasContainer.appendChild(canvas);
        //     // canvas.style.transform = 'scale(0.2)';
            document.getElementById('canvasHolder').appendChild(canvas);
        // }
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
          if(cbk) {
              cbk(canvas)
              return;
          }
          converOcr(pageNumber + 1)

        });
    });
    

}
