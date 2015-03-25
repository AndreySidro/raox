package ru.bmstu.rk9.rdo.generator

import java.util.HashMap

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet

import org.eclipse.xtext.generator.IFileSystemAccess

import ru.bmstu.rk9.rdo.IMultipleResourceGenerator

import ru.bmstu.rk9.rdo.compilers.RDOModelCompiler
import static extension ru.bmstu.rk9.rdo.compilers.RDOConstantCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDOSequenceCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDOFunctionCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDOResourceTypeCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDOPatternCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDODecisionPointCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDOFrameCompiler.*
import static extension ru.bmstu.rk9.rdo.compilers.RDOResultCompiler.*

import static extension ru.bmstu.rk9.rdo.RDOQualifiedNameProvider.*

import static extension ru.bmstu.rk9.rdo.generator.RDONaming.*
import static extension ru.bmstu.rk9.rdo.generator.RDOStatementCompiler.*

import ru.bmstu.rk9.rdo.rdo.RDOModel

import ru.bmstu.rk9.rdo.rdo.ResourceType

import ru.bmstu.rk9.rdo.rdo.ResourceDeclaration

import ru.bmstu.rk9.rdo.rdo.Constant

import ru.bmstu.rk9.rdo.rdo.Sequence

import ru.bmstu.rk9.rdo.rdo.Function

import ru.bmstu.rk9.rdo.rdo.Event
import ru.bmstu.rk9.rdo.rdo.Operation
import ru.bmstu.rk9.rdo.rdo.Rule

import ru.bmstu.rk9.rdo.rdo.DecisionPoint
import ru.bmstu.rk9.rdo.rdo.DecisionPointPrior
import ru.bmstu.rk9.rdo.rdo.DecisionPointSome
import ru.bmstu.rk9.rdo.rdo.DecisionPointSearch

import ru.bmstu.rk9.rdo.rdo.Frame

import ru.bmstu.rk9.rdo.rdo.Result
import ru.bmstu.rk9.rdo.rdo.OnInit
import ru.bmstu.rk9.rdo.rdo.TerminateCondition

class RDOGenerator implements IMultipleResourceGenerator
{
	override void doGenerate(Resource resource, IFileSystemAccess fsa)
	{}

	override void doGenerate(ResourceSet resources, IFileSystemAccess fsa)
	{
		exportVariableInfo(resources)

		val declarationList = new java.util.ArrayList<ResourceDeclaration>();
		for(resource : resources.resources)
			declarationList.addAll(resource.allContents.filter(typeof(ResourceDeclaration)).toIterable)

		val simulationList = new java.util.ArrayList<OnInit>();
		for(resource : resources.resources)
			simulationList.addAll(resource.allContents.filter(typeof(OnInit)).toIterable)

		val terminateConditionList = new java.util.ArrayList<TerminateCondition>();
		for(resource : resources.resources)
				terminateConditionList.addAll(resource.allContents.filter(typeof(TerminateCondition)).toIterable)

		var onInit = if(simulationList.size > 0) simulationList.get(0) else null;
		var term = if(terminateConditionList.size > 0) terminateConditionList.get(0) else null;

		for(resource : resources.resources)
			if(resource.contents.head != null)
			{
				val filename = (resource.contents.head as RDOModel).filenameFromURI

				for(e : resource.allContents.toIterable.filter(typeof(ResourceType)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileResourceType(filename,
						declarationList.filter[r | r.reference.fullyQualifiedName == e.fullyQualifiedName]))

				for(e : resource.allContents.toIterable.filter(typeof(Constant)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileConstant(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Sequence)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileSequence(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Function)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileFunction(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Operation)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileOperation(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Rule)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileRule(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Event)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileEvent(filename))

				for(e : resource.allContents.toIterable.filter[d |
						d instanceof DecisionPointSome || d instanceof DecisionPointPrior])
					fsa.generateFile(filename + "/" + (e as DecisionPoint).name + ".java",
						(e as DecisionPoint).compileDecisionPoint(filename))

				for(e : resource.allContents.toIterable.filter(typeof(DecisionPointSearch)))
					fsa.generateFile(filename + "/" + e.name + ".java",	e.compileDecisionPointSearch(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Frame)))
					fsa.generateFile(filename + "/" + e.name + ".java",	e.compileFrame(filename))

				for(e : resource.allContents.toIterable.filter(typeof(Result)))
					fsa.generateFile(filename + "/" + e.name + ".java", e.compileResult(filename))
			}

		fsa.generateFile("rdo_model/" + RDONaming.getProjectName(resources.resources.get(0).URI) +"Model.java",
			RDOModelCompiler.compileModel(resources, RDONaming.getProjectName(resources.resources.get(0).URI)))
		fsa.generateFile("rdo_model/Standalone.java", compileStandalone(resources, onInit, term))
		fsa.generateFile("rdo_model/Embedded.java", compileEmbedded(resources, onInit, term))
	}

	public static HashMap<String, GlobalContext> variableIndex = new HashMap<String, GlobalContext>

	def exportVariableInfo(ResourceSet rs)
	{
		variableIndex.clear
		for(r : rs.resources)
			variableIndex.put(r.resourceName, new GlobalContext)

		for(r : rs.resources)
		{
			val info = variableIndex.get(r.resourceName)

			for(rss : r.allContents.filter(typeof(ResourceDeclaration)).toIterable)
				info.resources.put(rss.name, info.newRSS(rss))

			for(seq : r.allContents.filter(typeof(Sequence)).toIterable)
				info.sequences.put(seq.name, info.newSEQ(seq))

			for(con : r.allContents.filter(typeof(Constant)).toIterable)
				info.constants.put(con.name, info.newCON(con))

			for(fun : r.allContents.filter(typeof(Function)).toIterable)
				info.functions.put(fun.name, info.newFUN(fun))
		}
	}

	def compileStandalone(ResourceSet rs, OnInit onInit, TerminateCondition term)
	{
		val project = RDONaming.getProjectName(rs.resources.get(0).URI)
		'''
		package rdo_model;

		import ru.bmstu.rk9.rdo.lib.*;
		@SuppressWarnings("all")

		public class Standalone
		{
			public static void main(String[] args)
			{
				long startTime = System.currentTimeMillis();

				Simulator.initSimulation();
				Simulator.initDatabase(«project»Model.modelStructure);
				Simulator.initModelStructureCache();
				Simulator.initTracer();

				System.out.println(" === RDO-Simulator ===\n");
				System.out.println("   Project «RDONaming.getProjectName(rs.resources.get(0).URI)»");
				System.out.println("      Source files are «rs.resources.map[r | r.contents.head.nameGeneric].toString»\n");

				«project»Model.init();

				«IF onInit != null»«FOR c :onInit.body»
					«c.compileStatement»
				«ENDFOR»«ENDIF»

				«IF term != null»
					«term.compileStatement»
				«ENDIF»

				«FOR r : rs.resources»
				«FOR c : r.allContents.filter(typeof(DecisionPoint)).toIterable»
					«c.fullyQualifiedName».init();
				«ENDFOR»
				«ENDFOR»

				«FOR r : rs.resources»
				«FOR c : r.allContents.filter(typeof(Result)).toIterable»
					«c.fullyQualifiedName».init();
				«ENDFOR»
				«ENDFOR»

				System.out.println("   Started model");

				int result = Simulator.run();

				if(result == 1)
					System.out.println("\n   Stopped by terminate condition");

				if(result == 0)
					System.out.println("\n   Stopped (no more events)");

				for(Result r : Simulator.getResults())
				{
					r.calculate();
					System.out.println(r.getData().toString(2));
				}

				System.out.println("\n   Finished model in " + String.valueOf((System.currentTimeMillis() - startTime)/1000.0) + "s");
			}
		}
		'''
	}

	def compileEmbedded(ResourceSet rs, OnInit onInit, TerminateCondition term)
	{
		val project = RDONaming.getProjectName(rs.resources.get(0).URI)
		'''
		package rdo_model;

		import java.util.List;

		import ru.bmstu.rk9.rdo.lib.*;
		@SuppressWarnings("all")

		public class Embedded
		{
			public static void initSimulation(List<AnimationFrame> frames)
			{
				Simulator.initSimulation();
				Simulator.initDatabase(«project»Model.modelStructure);
				Simulator.initModelStructureCache();
				Simulator.initTracer();

				«project»Model.init();

				«IF onInit != null»«FOR c :onInit.body»
					«c.compileStatement»
				«ENDFOR»«ENDIF»

				«IF term != null»
					«term.compileStatement»
				«ENDIF»

				«FOR r : rs.resources»
				«FOR c : r.allContents.filter(typeof(DecisionPoint)).toIterable»
					«c.fullyQualifiedName».init();
				«ENDFOR»
				«ENDFOR»

				«FOR r : rs.resources»
				«FOR c : r.allContents.filter(typeof(Result)).toIterable»
					«c.fullyQualifiedName».init();
				«ENDFOR»
				«ENDFOR»

				«FOR r : rs.resources»
				«FOR c : r.allContents.filter(typeof(Frame)).toIterable»
					frames.add(«c.fullyQualifiedName».INSTANCE);
				«ENDFOR»
				«ENDFOR»
			}

			public static int runSimulation(List<Result> results)
			{
				int result = Simulator.run();

				results.addAll(Simulator.getResults());

				return result;
			}
		}
		'''
	}
}

