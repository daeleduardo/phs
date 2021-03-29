<!DOCTYPE html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]>      <html class="no-js"> <!--<![endif]-->
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title></title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="style.css">
</head>

<body>
    <!--[if lt IE 7]>
            <p class="browsehappy">You are using an <strong>outdated</strong> browser. Please <a href="#">upgrade your browser</a> to improve your experience.</p>
        <![endif]-->
    <header class="header">
        <span>Formulário de teste</span>
    </header>
    <div id="conteudo" class="form">
    <?php

        require_once 'UI_Comp_Formulario.php';

        $comp = new UI_Comp_Formulario();        
        $errors = "";
        $validadescript = $_GET['validadescript'] ?? false;
        $comp->UI_Comp_Formulario($validadescript);

        if(!empty($_POST)){
            $comp->validate();
        }

        $comp->renderer(($_POST ?? false));

    ?>
    </div>
    <script src="script.js" async defer></script>
</body>

</html>