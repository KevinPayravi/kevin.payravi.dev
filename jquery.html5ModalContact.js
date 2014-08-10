/* 

	HTML5 Modal Contact Form
	Version:    3.0
	Created By: Tyler Colwell
	Website:    http://tyler.tc/
	
	Copyright © 2010 Tyler Colwell
	
*/

(function($){

	$.fn.html5ModalContact = function(options){
		
/*-----------------------------------------------------------------------------------*/
/*	Setup Options and Extend With Defaults
/*-----------------------------------------------------------------------------------*/

			var defaults = {
				// Popup Config
				method: "post",
				action: "process_form.php",
				shadow: "#FFFFFF",
				opacity: 70,
				advanced_close: false,
				// Fields Enabled
				firstn_on: true,
				lastn_on: false,
				email_on: true,
				subject_on: true,
				phone_on: false,
				// Field Labels
				firstn_label: 'Your First Name',
				lastn_label: 'Your Last Name',
				email_label: 'Your Email Address',
				subject_label:	'Message Subject',
				phone_label: 'Your Phone Number',
				message_label: 'Message',
				submit_label: 'Submit',
				close_label: 'Close',
				// Other
				subject_values: 'General,Technical,Feedback,Comments,Help and Support'
			};
			
			// Extend options and apply defaults if they are not set
			var options = $.extend(defaults, options);		

/*-----------------------------------------------------------------------------------*/
/*	Align Popup On Center
/*-----------------------------------------------------------------------------------*/

			tcformpop_recenter = function(){
				// Get window width and height to center the pop up
				var tcfpop = $("#tcformpop");
				var windowWidth = document.documentElement.clientWidth;
				var windowHeight = document.documentElement.clientHeight;
				var popupHeight = tcfpop.outerHeight(true);
				var popupWidth = tcfpop.width();
				// Simple division will let us make sure the box is centered on all screen resolutions
				tcfpop.css({"top": ( (windowHeight - popupHeight) / 2 ) + "px", "left": windowWidth/2-popupWidth/2});
				$("#tcformpop-bg").css({"height": windowHeight, 'opacity': '0.'+defaults.opacity});
			};
			
			// Bind to window resize
			$(window).resize(function(){
				tcformpop_recenter();
			});		
			
/*-----------------------------------------------------------------------------------*/
/*	Popup Close Handle
/*-----------------------------------------------------------------------------------*/

			tcformpop_close = function(){
						
				// Fade out the background shadow
				$('#tcformpop-bg').fadeOut("slow");
						
				// Fade out the modal itself
				$('#tcformpop').fadeOut("slow", function(){
					$('#tcformpop-bg').remove();
					$('#tcformpop').remove();				
				});
					
			};
			
/*-----------------------------------------------------------------------------------*/
/*	Create Handle To Open Popup
/*-----------------------------------------------------------------------------------*/

			$('.tcformpop-open').click(function(e){
				e.preventDefault();
				e.stopPropagation();
				tcformpop_display();
			});
				
/*-----------------------------------------------------------------------------------*/
/*	Generate Form Markup
/*-----------------------------------------------------------------------------------*/

			getPopHTML = function(){
				
				// Setup Vars
				var formFields = '';
				
				// First Name
				if( defaults.firstn_on == true ){
					formFields = formFields + '<div class="tcformpop-section"><label for="tcformpop_first">'+defaults.firstn_label+'</label><input required="required" class="tcformpop-input" name="tcformpop_first" id="tcformpop_first" type="text" placeholder="'+defaults.firstn_label+'"/><br class="tcformpop-clear" /></div>';
				}
				
				// Last Name
				if( defaults.lastn_on == true ){
					formFields = formFields + '<div class="tcformpop-section"><label for="tcformpop_last">'+defaults.lastn_label+'</label><input required="required" class="tcformpop-input" name="tcformpop_last" id="tcformpop_last" type="text" placeholder="'+defaults.lastn_label+'"/><br class="tcformpop-clear" /></div>';
				}
				
				// Email Address
				if( defaults.email_on == true ){
					formFields = formFields + '<div class="tcformpop-section"><label for="tcformpop_email">'+defaults.email_label+'</label><input required="required" type="email" class="tcformpop-input" name="tcformpop_email" id="tcformpop_email" type="text" placeholder="'+defaults.email_label+'"/><br class="tcformpop-clear" /></div>';
				}

				// Phone Number
				if( defaults.phone_on == true ){
					formFields = formFields + '<div class="tcformpop-section"><label for="tcformpop_phone">'+defaults.phone_label+'</label><input required="required" class="tcformpop-input" name="tcformpop_email" id="tcformpop_email" type="text" placeholder="'+defaults.phone_label+'"/><br class="tcformpop-clear" /></div>';
				}
				
				// Subject Field
				if( defaults.subject_on == true ){
					// Setup List Items
					var subjectList = '';
					var subArray = defaults.subject_values.split(',');
					for( var i=0; i < subArray.length; i++ ){
						subjectList = subjectList + '<option value="'+subArray[i]+'">'+subArray[i]+'</option>';						
					}
					// Build Element
					formFields = formFields + '<div class="tcformpop-section"><label for="tcformpop_email">'+defaults.subject_label+'</label><select name="tcformpop_subject" id="tcformpop_subject" class="tcformpop-input select">'+subjectList+'</select><br class="tcformpop-clear" /></div>';			
				}

				// Message Field
				formFields = formFields + '<div class="tcformpop-section"><label for="tcformpop_message">'+defaults.message_label+'</label><textarea required="required" rows="5" name="tcformpop_message" id="tcformpop_message" class="tcformpop-input textarea"></textarea><br class="tcformpop-clear" /></div>';			
				
				// Submit + Close Button
                formFields = formFields + '<div class="tcformpop-section last"><input type="hidden" name="tcformpop_submit" value="tcformpop_submit"/><input class="tcformpop-submit" type="submit" value="'+defaults.submit_label+'"/><input class="tcformpop-submit" type="button" onClick="tcformpop_close();" value="'+defaults.close_label+'"/></div>';

				// Create Popup Elements
				var popupForm = '<div id="tcformpop-bg" style="background:'+defaults.shadow+'"></div><div id="tcformpop"><div class="tcformpop-inner"><div class="tcformpop-overlay"><div id="tcformpop-form-wrap"><form id="tcformpop_form" name="tcformpop_form" action="" method="post">'+formFields+'<br class="tcformpop-clear" /></form></div></div></div></div>';
							
				// Return the pop up markup
				return popupForm;
				
			}; // end popup generator
			
/*-----------------------------------------------------------------------------------*/
/*	Display Popup
/*-----------------------------------------------------------------------------------*/
			
			tcformpop_display = function(){
				
				// Create a variable to hold the markup ( Needed For I.E )
				var markup = getPopHTML();
				
				// Prepend the popup into the body of the page
				$('body').append( markup );
																
				// Center on page
				tcformpop_recenter();
											
				// Display Popup
				$('#tcformpop-bg').fadeIn("slow");
				$('#tcformpop').fadeIn("slow");
								
/*-----------------------------------------------------------------------------------*/
/*	Advanced Close Handles
/*-----------------------------------------------------------------------------------*/

				if(defaults.advanced_close == true){
					
					console.log('Advanced Close On');
					
					// detect key up
					$(document).keyup(function(e){
						
						// of escape key
						if(e.keyCode == 27){
							
							console.log('escape hit!');
							
							// dump the popup  
							tcformpop_close();
										   
						} // end if escape key
								  
					}); // end key up event
					
														
					// detect click in body and dump the popup
					$('body').click(function(event){
												
						// Only allow if form is not submitted yet
						if( $('.tcformpop-success').length == 0 ){
							tcformpop_close();
						}
						
					}); // end body detect
					
					// Detect a click in the popup area to prevent it from closing
					$('#tcformpop').click(function(event){
						
						// Strop prop. of close event
						event.stopPropagation();
						
					}); // end popup click detection
					 
				} // end advanced close	
				
/*-----------------------------------------------------------------------------------*/
/*	Form Submit Handle
/*-----------------------------------------------------------------------------------*/

				$('#tcformpop_form').submit(function(){
					
					// Get form data to send to php script
					var data = $(this).serialize();
					var submit_button = $(this).find(":submit");
					
					// Change Button
					submit_button.attr('value','Sending...');
					submit_button.attr('disabled', 'disabled');
					
					// Send form data via Ajax
					$.ajax({
						type: defaults.method,
						url: defaults.action,
						data: data,
						// On success of sending dispay the message
						success: function(html){
							$('#tcformpop-form-wrap').html(html);
							// Bind close action to close button
							$(".tcformpop-close").bind("click", tcformpop_close);
						}
					});
									
					// RETURN FALSE TO STOP ACCIDENTAL FORM SUBMIT / PAGE RELOAD
					return false;
					
				}); // end form submit
				
			}; // end popup display function
			
/*-----------------------------------------------------------------------------------*/
/*	All Done!
/*-----------------------------------------------------------------------------------*/			
												
	}; // End Main Function

})(jQuery); // End Plugin