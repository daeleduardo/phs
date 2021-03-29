function validateScript(){
    const limit_txt = 144;
    const limit_txt_grande = 255;            
    const re_txt = /[^a-{\s}]/gm;
    const re_txt_grande = /[^A-Z0-9-{\s}]/gm;
    const re_date = /([0-9]|1[012])[\/.]([0-9]|[12][0-9]|3[01])[\/.](19|20)\d\d/;
    let error_msg = "";
    let txt = "";

    let between = (num,min,max) => {
        return num >=min && num <=max;
    };

    
    txt = document.getElementById("texto").value;
    if (re_txt.test(txt) || !between(txt.length,1,limit_txt)) {
        error_msg += "\n\n*  Texto pequeno inválido.";
    }

    txt = document.getElementById("texto_grande").value;
    if (re_txt_grande.test(txt) || !between(txt.length,1,limit_txt_grande)) {
        error_msg += "\n\n*  Texto grande inválido.";
    }

    txt = document.getElementById("data").value;
    const matched_date = txt.match(re_date);
    if (matched_date === null || matched_date[0] != txt) {
        error_msg += "\n\n*  Data inválida.";
    }       

    if (error_msg.length > 0){
        error_msg = "Dados inválidos: " + error_msg;
        alert(error_msg);
    }

    return error_msg.length == 0;
    
}