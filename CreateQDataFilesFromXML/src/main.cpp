#include "QData.hxx"
#include <yaml-cpp/yaml.h>
#include <string>
#include <sstream>
#include <cstdlib>
#include <iostream>
#include <fstream>

template <class N>
std::string toString(N a)
{
	std::stringstream m;
	m << a;
	return m.str();
}


int main(int argc, const char* argv[])
{
	try
	{
		std::string qdataxmlfilen;
		if(argc < 2)
		{
			if(getenv("QDATA_XML_FILE") == NULL)
			{
				std::cout << "Please set the QDATA_XML_FILE variable or supply an argument." << std::endl;
				exit(0);
			}
			else
			{
				qdataxmlfilen = getenv("QDATA_XML_FILE");
			}
		}
		else
		{
			qdataxmlfilen = argv[1];
		}
		
		std::auto_ptr<qdata_t> doc(qdata(qdataxmlfilen));
		YAML::Node outdoc;

		if(std::string(doc->type()) == "ELEMENT")
		{	
			if(!doc->header().present())
			{
				std::cout << "Document declared ELEMENT type, yet missing <header> element." << std::endl;
				exit(-1);
			}
			YAML::Node odoc;
			outdoc["header"].push_back(odoc);
			header_t h = doc->header().get();
			odoc["name"] = std::string(h.name());
			odoc["author"] = std::string(h.author());
			odoc["description"] = std::string(h.description());
			odoc["extra"] = std::string(h.extra());
			odoc["maxquestions"] = int(h.maxquestions());
			if(h.skipoverride().present())
				odoc["skipoverride"] = bool(h.skipoverride().get());
			if(h.answernumberinput().present())
				odoc["answernumberinput"] = bool(h.answernumberinput());
			if(h.skipisincorrect().present())
				odoc["skipisincorrect"] = bool(h.skipisincorrect());
			if(h.quizmode().present())
				odoc["quizmode"] = bool(h.quizmode());

			if(!doc->questions().present())
			{
				std::cout << "Document declared ELEMENT type, yet missing <questions> element." << std::endl;
				exit(-1);
			}
			YAML::Node qdoc;
			outdoc["questions"].push_back(qdoc);
			questions_t q = doc->questions().get();
			questions_t::problem_sequence& qseq = q.problem();
			int index = 1;
			for(questions_t::problem_iterator iter = qseq.begin();
				iter != qseq.end();
				iter++)
			{
				question_t ques(*iter);
				YAML::Node cques;
				qdoc["q" + toString(index)].push_back(cques);
				cques["question"] = std::string(ques.question());
				answers_t answers = ques.answers();
				YAML::Node answersnode;
				cques["answers"] = answersnode;
				answers_t::answer_sequence& aseq = answers.answer();
				for(answers_t::answer_iterator iter2 = aseq.begin();
					iter2 != aseq.end();
					iter2++)
				{
					answersnode.push_back(std::string(*iter2));
				}
				cques["correctanswer"] = int(ques.correctanswer());
				index++;
			}
		}
		else if (std::string(doc->type()) == "ATTRIBUTE")
		{
			if(!doc->headera().present())
			{
				std::cout << "Document declared ATTRIBUTE type, yet missing <headera> element." << std::endl;
				exit(-1);
			}
			YAML::Node odoc;
			outdoc["header"] = odoc;
			headera_t h = doc->headera().get();
			odoc["name"] = std::string(h.name());
			odoc["author"] = std::string(h.author());
			odoc["description"] = std::string(h.description());
			odoc["extra"] = std::string(h.extra());
			odoc["maxquestions"] = int(h.maxquestions());
			if(h.skipoverride().present())
				odoc["skipoverride"] = bool(h.skipoverride().get());
			if(h.answernumberinput().present())
				odoc["answernumberinput"] = bool(h.answernumberinput());
			if(h.skipisincorrect().present())
				odoc["skipisincorrect"] = bool(h.skipisincorrect());
			if(h.quizmode().present())
				odoc["quizmode"] = bool(h.quizmode());

			if(!doc->questionsa().present())
			{
				std::cout << "Document declared ATTRIBUTE type, yet missing <questionsa> element." << std::endl;
				exit(-1);
			}
			YAML::Node qdoc;
			outdoc["questions"] = qdoc;
			questionsa_t q = doc->questionsa().get();
			questionsa_t::problem_sequence& qseq = q.problem();
			int index = 1;
			for(questionsa_t::problem_iterator iter = qseq.begin();
				iter != qseq.end();
				iter++)
			{
				questiona_t ques(*iter);
				YAML::Node cques;
				qdoc["q" + toString(index)] = cques;
				cques["question"] = std::string(ques.question());
				answersa_t answers = ques.answers();
				YAML::Node answersnode;
				cques["answers"] = answersnode;
				answersa_t::answer_sequence& aseq = answers.answer();
				for(answersa_t::answer_iterator iter2 = aseq.begin();
					iter2 != aseq.end();
					iter2++)
				{
					answera_t ans(*iter2);
					answersnode.push_back(std::string(ans.value()));
				}
				cques["correctanswer"] = int(ques.correctanswer());
				index++;
			}
		}

		std::ofstream fout((doc->name() + ".lsybin").c_str());
		if(fout.is_open())
		{
			fout << outdoc;
			fout.close();
		}
		else
		{
			std::cout << "Error opening/creating file." << std::endl;
			exit(0);
		}
	}
	catch (const xml_schema::exception& ex) {
		std::cout << ex << std::endl;
	}
}
