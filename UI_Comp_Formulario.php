<?php
declare (strict_types = 1);

class UI_Comp_Formulario
{
    public  $errors;
    private $validateScript;

    /**
     * @param bool $validateScript
     * @return void
     */

    public function UI_Comp_Formulario(bool $validateScript = false): void
    {
        $this->validateScript = $validateScript;
    }


    /**
     * @param mixed $param
     * @return void
     */    
    public function renderer($param = false): void
    {
        $params = [
            "validateScript"=>$this->validateScript,
            "errors"=>$this->errors
        ];
        
        if (is_array($params)){
            $params = array_merge($params,$param);
            unset($param);
        }
        extract($params);
        unset($params);
        include 'Template.php';
    }

    /**
     * @return bool
     * @throws \Throwable
     */    
    public function validate(): bool
    {
        $return = true;
        $this->errors  = "";
        try {
            $limit_txt = 144;
            $limit_txt_grande = 255;
            $re_txt = "/[^a-{\s}]/m";
            $re_txt_grande = "/[^A-Z0-9-{\s}]/m";
            $er_date = "/([0-9]|1[012])[\/.]([0-9]|[12][0-9]|3[01])[\/.](19|20)\d\d/";

            $between = function ($num,$min,$max) {
                return ($num >=$min && $num <=$max);
            };
            
            $texto = $_POST['texto']??"";
            if (preg_match($re_txt, $texto) || !$between(strlen($texto),1,$limit_txt)) {

                $this->errors .= "<li>Texto pequeno inválido.</li>";
                $return = false;
            }
            
            $texto_grande = $_POST['texto_grande']??"";
            
            if (preg_match($re_txt_grande, $texto_grande) || !$between(strlen($texto_grande),1,$limit_txt_grande) ) {
                $this->errors .= "<li>Texto grande inválido.</li>";
                $return = false;
            }

            $data = $_POST['data'] ?? "";
            if (!preg_match($er_date,$data)) {
                $this->errors .= "<li>Data inválida.</li>";
                $return = false;
            }            

        } catch (\Throwable $th) {
            $this->errors .= "<li>$th::getMessage()</li>";
            $return = false;
        }
        finally{
            return $return;
        }
    }

}
