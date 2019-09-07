string override(string page)
{
	return "I can't continue to support this game, given the reports of Zack Johnson's abuse. Due to the lack of response from the development team, this script has been modified in an attempt to spread information any way I can.";
}

void main()
{
	override(visit_url()).write();
}
