        <?php if ($validateScript): ?>
            <form onsubmit="return validateScript()" action="index.php" method="POST" target="_self">
        <?php else: ?>
            <form  action="index.php" method="POST" target="_self">
        <?php endif; ?>
            <fieldset>
                <div class="form-group"><label for="data">Data:</label><input id="data" name="data" type="text" <?php echo (isset($data))?"value='".$data."'":""; ?> /></div>
                <div class="form-group"><label for="texto">Texto:</label><input id="texto" name="texto" type="text" <?php echo (isset($texto))?"value='".$texto."'":""; ?> /></div>
                <div class="form-group"><label for="checkbox">Checkbox?</label><input id="checkbox" name="checkbox" type="checkbox" <?php echo (isset($checkbox))?"checked":""; ?>  /></div>
                <div class="form-group"><label for="texto_grande">Texto grande:</label><Textarea id="texto_grande" name="texto_grande" cols="24" ><?= $texto_grande ?? "" ?></Textarea></div>
                <div class="form-group"><button>Submit</button></div>
            </fieldset>
            <span>Teste de formulário</span>
            <div id="errors"><ul><?php echo $errors; ?></ol><div>
        </form>
        
        