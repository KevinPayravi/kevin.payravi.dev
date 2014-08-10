<?PHP

/*-----------------------------------------------------------------------------------*/
/*	Sender Setup
/*-----------------------------------------------------------------------------------*/

// Where should the message be sent
$to = "YOUREMAIL@DOMAIN.COM";

/////////////////////////////////////////////

// Check if form is submitted
if(isset($_POST['tcformpop_submit'])){
	
	// Setup form vars
	$first_name = isset($_POST['tcformpop_first']) ? strip_tags($_POST['tcformpop_first']) : '';
	$last_name = isset($_POST['tcformpop_last']) ? strip_tags($_POST['tcformpop_last']) : '';
	$phone = isset($_POST['tcformpop_phone']) ? strip_tags($_POST['tcformpop_phone']) : 'N/A';
	$subject = isset($_POST['tcformpop_subject']) ? strip_tags($_POST['tcformpop_subject']) : 'Contact Form Message';
	$email = strip_tags($_POST['tcformpop_email']);
	$message = nl2br( strip_tags($_POST['tcformpop_message']) );
	
	// Add Other Info To Message
	$message.= "<br>" . "Name: " . $first_name . " " . $last_name;
	$message.= "<br>" . "Phone Number: " . $phone;
	
	// Create email Headers
	$headers  = "MIME-Version: 1.0\n";
	$headers .= "Content-type: text/html; charset=utf-8\n";
	$headers .= "From: '".$first_name." ".$last_name."' <".$email."> \n";

	// If email is sent
	if(mail($to, $subject, $message, $headers)){
		
		// Display sent message
		echo '<p class="tcformpop-reply success tcformpop-close"><strong>Success!</strong>  Thank you, your message has been sent and we will get back to you shortly.</p>';
		
	} else { // If mail could not be sent
	
		echo '<p class="tcformpop-reply error tcformpop-close"><strong>Uh Oh!</strong>  Looks like there was an error when sending your message. This does not happen often, please try again in a moment.</p>';
		
	} // End if mail sent / not sent
		
} // End if form submitted

?>