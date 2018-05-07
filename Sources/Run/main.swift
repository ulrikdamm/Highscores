import App

if #available(OSX 10.12, *) {
	try app(.detect()).run()
} else {
	// Fallback on earlier versions
}
