#!/bin/ruby -Ks
require 'optparse'
require 'logger'

####
# OptionParser Class
#  Usage:
#    -i : Input Directory [not null]
#    -r : Reflection ( Option default=false )
#    -l : Loglevel   ( Option default=ERROR )
#    -o : Output Directory ( Option default=Input Directory)
###
class OptParser

public
    attr_reader :mOptions

    # Constractor
    def initialize
        @mParser = OptionParser.new
        @mOptions = Hash::new
        initializeParameter
    end

    def parse (aArgs)
        setParseRule
        @mParser.parse!(aArgs)
        p @mOptions
    end

private 
    def initializeParameter
        @mOptions[':loglevel'] = Logger::ERROR
        @mOptions[':input'] = ""
        @mOptions[':reflection'] = false
        @mOptions[':output'] = ""
    end

    def setParseRule
        @mParser.on('-i VALUE', 'Directory Name') { |v|
            @mOptions[':input'] = v.to_s
        }
        @mParser.on('-r [BOOLEAN]' , 'Reflection value=[on/off] : (Defaule off)') { |v|
            @mOptions[':reflection'] = true
        }
        @mParser.on('-l [VALUE]' , 'Loglevel value=[0-5] (Default=0)' ) { |v| 
            @mOptions[':loglevel'] = Ogg2Mp3Translator::translateOptLogLevelToLoggerLevel( v )
        }
        @mParser.on('-o [VALUE]' , 'Output Directory (Default=Current)' ) { |v|
            @mOptions[':output'] = v
        }
    end
end

####
# FFmpeg2CommandExecutor
#  Usage:
###
class FFmpeg2CommandExecutor
    @mOptions = {}
    # Constractor
    def initialize( aOption )
        @mLogger = Logger.new(STDOUT)
        @mOptions = aOption
    end

    def exec
        outputDirectory = @mOptions[':output']
        getOggFileList( @mOptions[':input'] , @mOptions[':reflection'] ).each { | oggFile | 
             if !system( buildCommand ( oggFile , outputDirectory ) ) 
                @mLogger.error('ffmpeg Command error.See ffmpeg command detail.')
             end
        }
    end
    
private
    def getOggFileList( aInputDir, aReflection )
        searchWord = "/*.ogg"
        if aReflection
            searchWord = "/**/*.ogg"
        end
        searchFilePath = aInputDir.to_s + searchWord
        filePathList = Array.new
        Dir.glob(searchFilePath.gsub("//","/")).each { | f |
            filePathList.push( f )
        }
        return filePathList
    end

    def buildCommand( aInputFileName, aOutputDirectory )
        cmd = "ffmpeg"
        cmd_opt_input = "-i"
        cmd_opt_lame_encoder= "-acodec libmp3lame"
        cmd_opt_bitrate= "-ab 192k"

        exec_cmd = cmd + " " + cmd_opt_input + " "  + getInputFilename( aInputFileName ) + " " + cmd_opt_lame_encoder + " " + cmd_opt_bitrate + " "  + getOutputFilename( aInputFileName , aOutputDirectory ) 
        p exec_cmd
        return exec_cmd
    end

    def getInputFilename ( aInputFileName )
        return aInputFileName 
    end

    def getOutputFilename( aInputFileName, aOutputDirectory )
        dir      = File.dirname(aInputFileName)
        filename = File.basename(aInputFileName).gsub("ogg","mp3")
        if !aOutputDirectory.empty?
            dir = aOutputDirectory.to_s
        end
        output = dir + "/" + filename
        print output
        return output
    end
end

####
# Ogg2Mp3Translator
####
class Ogg2Mp3Translator
    def self.translateOptLogLevelToLoggerLevel( aLogLevel )
        case aLogLevel
            when 0
                return Logger::ERROR
            when 1
                return Logger::WARN
            when 2
                return Logger::INFO
            when 3
                return Logger::DEBUG
            else
                return Logger::UNKNOWN
        end
    end
end

####
# Ogg2Mp3
####
class Ogg2Mp3
    # Constractor
    def initialize ( aOpt )
        @mParser = OptParser.new
        @mLogger = Logger.new(STDOUT)
        @mCommandExecutor = FFmpeg2CommandExecutor.new( @mParser.mOptions )

        # Parse Argment
        @mParser.parse( aOpt )
        
        # Initialize Logger
        initializeLoggingParameter 
    end

    def exec
        if !validate
            # Nothing...
            return;
        end
        # execute
        @mCommandExecutor.exec
    end

private 
    # Initialize Logger
    def initializeLoggingParameter
        @mLogger.level = @mParser.mOptions[':loglevel']
    end

    def validate
        # Chack option ( Is -i parameter empty? )
        if @mParser.mOptions[':input'].empty?
            @mLogger.error('Ogg2Mp3 Validation Error. Input directoryName is Empty. Please check -i option');
            return false
        end
        
        # Check exist of Input Directory 
        if !File.exist?( @mParser.mOptions[':input'] )
            @mLogger.error('Ogg2Mp3 Validation Error. Directory is not exist. Please check -i option');
            return false
        end

        if @mParser.mOptions[':output'].empty?
            return true
        end

        # Check exist of Output Directory 
        if !File.exist?( @mParser.mOptions[':output'] )
            @mLogger.error('Ogg2Mp3 Validation Error. Directory is not exist. Please check -o option');
            return false
        end
        return true
    end
end

main = Ogg2Mp3.new( ARGV )
main.exec
