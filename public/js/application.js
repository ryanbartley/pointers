var eResults;
var eForm;
var resultsContent = "";
var haveValidation = false;
var validOkay = true;

function checkFirstName(elem) {
	t = elem;
}

function output( s ) {
	eResults.innerHTML += '<p>' + s + '</p>';
}

function errorOutput( s ) {
	eResults.innerHTML += '<p class="error">' + s + '</p>';
}

function clearOutput() {
	eResults.innerHTML = '';
}

function isValid( e ) {
	if(e.validity.valid == true) {
		return true;
	} else {
		m = e.validationMessage;
		errorOutput(e.name + ': ' + m);
		validOkay = false;
		return false;
	}
}

function dispValue( e ) {
	alert("I'm in the dispValue function");
	v = function(s) { return e.name + ': ' + s }

	if (e.type == "radio") {
		if(e.checked) return v(e.value);
		else return "";
	}

	if (e.type == "select-multiple") {
		a = [];
		for (var i = 0; i < e.length; i++) {
			if(e[i].selected) a.push(e[i].value);
		}
		return v(a.join(', '));
	}

	if(e.type == "checkbox") return v( e.checked ? "on" : "off" );

	else return v(e.value);
}

function display() {
	clearOutput();
	if(!haveValidation) {
		errorOutput('This platform does not support the HTML5 validation API.');		
	}
	validOkay = true;
	for (var i = 0; i < eForm.length; ++i) {
		var e = eForm.elements[i];
		var name = e.name;
		if(!haveValidation) output(dispValue(e));
		if(haveValidation && isValid(e)) {
			output(dispValue(e));
		}
	}
}

//function init() {

	//eForm = document.getElementById('signup');
	//eResults = document.getElementById('results');
	//alert("I'm inside the javascript");

	//haveValidation = (typeof eForm.elements[0].validity === 'object');

//}

//window.onload = init;