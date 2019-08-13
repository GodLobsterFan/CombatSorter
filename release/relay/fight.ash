record combat_rec {
   string ufname;          // user-friendly name, not really used by BatBrain
   string dmg;             // damage to monster
   string pdmg;            // damage to player
   string special;         // comma-delimited list of other action results
};

string classify(string kind, string menu)
{
	static 
	{
		combat_rec [string, int] factors;
		file_to_map("batfactors.txt",factors);
	}
	string [int] types = {
		0:"<option value='none'>- DAMAGE -</option>", 
		1:"<option value='none'>- RESTORE -</option>",
		2:"<option value='none'>- DELEVEL -</option>",
		3:"<option value='none'>- BUFF -</option>",
		4:"<option value='none'>- ABSCOND -</option>",
		5:"<option value='none'>- COPY -</option>",
		6:"<option value='none'>- BANISH -</option>",
		7:"<option value='none'>- YELLOW RAY -</option>",
		8:"<option value='none'>- OTHER -</option>",
	};
	
	matcher skills;
	if (kind == "skill")
	{
		skills = '<option value="(.*?)".*?<\/option>'.create_matcher(menu);
	}
	else if (kind == "item")
	{
		skills = '<option picurl=.*? value=(.*?)>.*?<\/option>'.create_matcher(menu);
	}
	boolean other = true;
	
	while (skills.find())
	{
		combat_rec s = factors[kind, to_int(group(skills,1))];
		other = true;
		
		if (s.special.contains_text("banish"))
		{
			types[6] += group(skills,0);
			other = false;
		}
		else if (s.special.contains_text("insta") || s.special.contains_text("runaway"))
		{
			types[4] += group(skills,0);
			other = false;
		}
		else if (s.dmg != "0")
		{
			types[0] += group(skills,0);
			other = false;
		}
		if (s.pdmg != "0")
		{
			types[1] += group(skills,0);
			other = false;
		}
		if (s.special.contains_text("att -") || s.special.contains_text("def -"))
		{
			types[2] += group(skills,0);
			other = false;
		}
		if (s.pdmg == "0" && (s.special.contains_text("%") || s.special.contains_text(" +") || s.special.contains_text("buff")))
		{
			types[3] += group(skills,0);
			other = false;
		}
		if (s.special.contains_text("attract") || s.special.contains_text("copy") || group(skills,1) == "7274")
		{
			types[5] += group(skills,0);
			other = false;
		}
		if (s.special.contains_text("yellow"))
		{
			types[7] += group(skills,0);
			other = false;
		}
		if (other)
		{
			types[8] += group(skills,0);
		}
	}
	string s = '';
	foreach t in types
	{
		if (length(types[t]) > 60)
		{
			s += types[t];
		}
	}
	return s;
}

string override(string page)
{
	matcher items = "(?<=<select name=whichitem2?>)(.*?)(?=<\/select>)".create_matcher(page);
	matcher selected = 'selected (value=.*?>)'.create_matcher(page);

	if (items.find())
	{
		string newitems = classify("item", group(items,0)).replace_string("selected value", "value");
		
		if (selected.find())
		{
			repeat
			{
				page = page.replace_string(group(items,0), newitems.replace_string(group(selected, 1), group(selected, 0)));
				items.find();
			}
			until (!selected.find());
		}
		else
		{
			repeat
			{
				page = page.replace_string(group(items,0), newitems);
			}
			until (!items.find());
		}
	}
	
	matcher skills = "(?<=<select name=whichskill>).*?(?=<\/select>)".create_matcher(page);
	if (skills.find())
	{
		page = skills.replace_first(classify("skill", group(skills,0)));
	}

	return page;
}

void main()
{
	override(visit_url()).write();
}
